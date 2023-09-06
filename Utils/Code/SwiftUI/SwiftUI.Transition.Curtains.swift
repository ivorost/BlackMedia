//
//  SwiftUI.Transition.Curtains.swift
//  Utils
//
//  Created by Ivan Kh on 11.04.2023.
//

import SwiftUI

private protocol CurtainsViewProtocol {
    func animateAsync(duration: CFTimeInterval)
}

public extension View {
    @ViewBuilder func curtains(removal: Bool, duration: CFTimeInterval) -> some View {
        modifier(CurtainsModifier(removal: removal, duration: duration))
    }
}

private struct CurtainsModifier: ViewModifier {
    let removal: Bool
    let duration: CFTimeInterval

    func body(content: Content) -> some View {
        Curtains(duration: duration, animate: removal) {
            content
        }
    }
}

public struct Curtains<TContent: View>: AppleViewRepresentable {
    let duration: CFTimeInterval
    let animate: Bool
    let content: () -> TContent

    public init(duration: CFTimeInterval, animate: Bool, @ViewBuilder content: @escaping () -> TContent) {
        self.duration = duration
        self.animate = animate
        self.content = content
    }

    public func makeUIView(context: Context) -> AppleView {
        return CurtainsView(content: content)
    }

    public func makeNSView(context: Context) -> AppleView {
        return makeUIView(context: context)
    }

    public func updateUIView(_ uiView: AppleView, context: Context) {
        if animate {
            (uiView as? CurtainsViewProtocol)?.animateAsync(duration: duration)
        }
    }

    public func updateNSView(_ uiView: AppleView, context: Context) {
        updateUIView(uiView, context: context)
    }
}


private class CurtainsView<TContent: View>: BuilderView<TContent>, CurtainsViewProtocol {
    private var animating = false

    func animateAsync(duration: CFTimeInterval) {
        guard !animating else { return }
        animating = true
        DispatchQueue.main.async { self.animate(duration: duration) }
    }

    func animate(duration: CFTimeInterval) {
        guard animating else { return }
        #if canImport(AppKit)
        guard let layer else { return }
        #endif
        guard let snapshot = asImage() else { return }
        let leftLayer = self.layer(snapshot: snapshot.left, gravity: .left)
        let rightLayer = self.layer(snapshot: snapshot.right, gravity: .right)

        print("animate")
        layer.sublayers?.forEach { $0.isHidden = true }
        layer.addSublayer(leftLayer)
        layer.addSublayer(rightLayer)
        animatePosition(layer: leftLayer, to: -layer.bounds.width / 2, duration: duration)
        animatePosition(layer: rightLayer, to: layer.bounds.width / 2, duration: duration)
        animateOpacity(layer: leftLayer, to: 0, duration: duration)
        animateOpacity(layer: rightLayer, to: 0, duration: duration)
    }

    private func layer(snapshot: CGImage, gravity: CALayerContentsGravity) -> CALayer {
        let layer = CALayer()
        #if canImport(UIKit)
        layer.contentsScale = AppleScreen.main.scale
        layer.bounds = self.layer.bounds
        #endif
        #if canImport(AppKit)
        layer.contentsScale = AppleScreen.main?.backingScaleFactor ?? 1
        layer.bounds = self.layer?.bounds ?? .zero
        #endif
        layer.anchorPoint = .init(x: 0, y: 0)
        layer.contentsGravity = gravity
        layer.contents = snapshot
        return layer
    }

    private func animatePosition(layer: CALayer, to x: CGFloat, duration: CFTimeInterval) {
        let animation = CABasicAnimation(keyPath: "position")
        let newPosition = CGPoint(x: x, y: layer.position.y)
        animation.duration = duration
        animation.fromValue = layer.position
        animation.toValue = newPosition
        layer.add(animation, forKey: nil)
        layer.position = newPosition
    }

    private func animateOpacity(layer: CALayer, to opacity: Float, duration: CFTimeInterval) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = duration
        animation.fromValue = layer.opacity
        animation.toValue = opacity
        layer.add(animation, forKey: nil)
        layer.opacity = opacity
    }

    private func asImage() -> (left: CGImage, right: CGImage)? {
        #if canImport(UIKit)
        let bounds = self.bounds
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
        guard let cgImage = image.cgImage else { return nil }

        let halfWidth = CGFloat(cgImage.width)
        let leftRect = CGRectMake(0, 0, halfWidth / 2, CGFloat(cgImage.height))
        let rightRect = CGRectMake(halfWidth / 2, 0, halfWidth / 2, CGFloat(cgImage.height))

        guard
            let leftImage = cgImage.cropping(to: leftRect),
            let rightImage = cgImage.cropping(to: rightRect)
        else { return nil }

        return (left: leftImage, right: rightImage)
        #endif

        #if canImport(AppKit)
        assertionFailure()
        return nil
        #endif
    }
}


