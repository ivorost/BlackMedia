//
//  AVFoundation.SampleBuffer.swift
//  Capture
//
//  Created by Ivan Kh on 30.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation
#if os(iOS)
import UIKit
#endif


public class SampleBufferDisplayLayer : AVSampleBufferDisplayLayer {
    public enum Rotation : UInt8 {
        case portrait = 1
        case portraitUpsideDown = 3
        case landscapeLeft = 6
        case landscapeRight = 8
    }
    
    
    private var originalAffineTransform = CGAffineTransform()
    private var videoRotation: Rotation?
    private var videoDimensions: CMVideoDimensions?
    
    public override var anchorPoint: CGPoint {
        get {
            return CGPoint(x: 0.5, y: 0.5)
        }
        set {
            super.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        }
    }
    
    public override func setAffineTransform(_ m: CGAffineTransform) {
        originalAffineTransform = m
        updateAffineTransform(m)
    }

    public func setVideo(rotation: Rotation, dimensions: CMVideoDimensions) {
        guard videoRotation != rotation else { return }
        
        videoRotation = rotation
        videoDimensions = dimensions
        updateAffineTransform(originalAffineTransform)
    }
        
    private func calcAngle(_ rotation: Rotation) -> Int {
        switch rotation {
        case .portrait:
            return 0
        case .portraitUpsideDown:
            return 180
        case .landscapeLeft:
            return 90
        case .landscapeRight:
            return -90
        }
    }
    
    private func calcAngle(video: Rotation, device: Rotation) -> Int {
        let videoAndgle = calcAngle(video)
        let deviceAngle = calcAngle(device)
        
        #if os(iOS)
        return deviceAngle - videoAndgle
        #else
        return videoAndgle - deviceAngle
        #endif
    }
    
    private func updateAffineTransform(_ m: CGAffineTransform) {
        guard let rotation = videoRotation else {
            super.setAffineTransform(m); return
        }
        
        var transform = m
        var deviceRotation: Rotation
        #if os(iOS)
        deviceRotation = .portrait
        #else
        deviceRotation = .portrait
        #endif
        
        let angle = calcAngle(video: rotation, device: deviceRotation)
        
        print("angle \(angle)")
        
        if false { }
        else if angle == 90 {
            transform = transform.rotated(by: .pi / 2.0)
        }
        else if angle == -90 {
            transform = transform.rotated(by: .pi / -2.0)
        }
        else if angle == 180 {
            transform = transform.rotated(by: .pi)
        }
        else if angle == -180 {
            transform = transform.rotated(by: .pi / -1)
        }
        
//        switch rotation {
//        case .portrait:
//             break
//        case .portraitUpsideDown:
//            transform = transform.translatedBy(x: CGFloat(dimensions.width), y: CGFloat(dimensions.height))
//            transform = transform.rotated(by: .pi)
//        case .landscapeLeft:
//            transform = transform.translatedBy(x: CGFloat(dimensions.width), y: 0)
//            transform = transform.rotated(by: .pi / 2.0)
//        case .landscapeRight:
//            transform = transform.translatedBy(x: 0, y: CGFloat(dimensions.height))
//            transform = transform.rotated(by: .pi / 2.0)
//        break
//        }
        
        super.setAffineTransform(transform)
    }
}


public class SampleBufferDisplayView : AppleView {
    
    #if os(iOS)
    override open class var layerClass: Swift.AnyClass {
        return SampleBufferDisplayLayer.self
    }
    #else
    public override func makeBackingLayer() -> CALayer {
        return SampleBufferDisplayLayer()
    }
    #endif
    
    public var sampleLayer: SampleBufferDisplayLayer {
        get {
            return layer as! SampleBufferDisplayLayer
        }
    }
}

#if os(iOS)
public extension SampleBufferDisplayLayer.Rotation {
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeLeft
        case .landscapeRight:
            self = .landscapeRight
        default:
            return nil
        }
    }
}
#endif
