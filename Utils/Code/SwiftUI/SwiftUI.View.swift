//
//  SwiftUI.View.swift
//  Utils
//
//  Created by Ivan Kh on 10.03.2023.
//

import SwiftUI

class BuilderView<TContent: View>: UIView {
    private var hostingView: UIView?
    private var hostingController: UIViewController?

    convenience init(content: @escaping () -> TContent) {
        self.init()
        update(content: content)
    }

    func update(content: @escaping () -> TContent) {
        let content = content()

        hostingView?.removeFromSuperview()
        hostingView = nil
        hostingController = nil

        let hostingController = UIHostingController(rootView: content)
        guard let hostingView = hostingController.view
        else { return }

        addSubview(filling: hostingView)
        self.hostingView = hostingView
        self.hostingController = hostingController
    }
}

public extension View {
    func Print(_ vars: Any...) -> some View {
        for v in vars { print(v) }
        return self
    }

    func frame(size: CGSize, alignment: Alignment = .center) -> some View {
        frame(width: size.width, height: size.height, alignment: alignment)
    }

    func offset(_ point: CGPoint) -> some View {
        offset(CGSize(width: point.x, height: point.y))
    }
}
