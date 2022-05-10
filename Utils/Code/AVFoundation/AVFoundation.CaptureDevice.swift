//
//  AVFoundation.CaptureDevice.swift
//  Utils
//
//  Created by Ivan Kh on 20.04.2022.
//

import Foundation
import AVFoundation

public extension AVCaptureDevice {
    static var rearCamera: AVCaptureDevice? {
        return camera(at: .back)
    }

    static var frontCamera: AVCaptureDevice? {
        return camera(at: .front)
    }
    
    static var unspecifiedCamera: AVCaptureDevice? {
        return camera(at: .unspecified)
    }


    private static func camera(at position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        #if os(iOS)
        if let device = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: position) {
            return device
        }
        #endif

        #if os(iOS)
        if let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: position) {
            return device
        }
        #endif

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            return device
        }

        #if os(iOS)
        if let device = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: position) {
            return device
        }
        #endif

        #if os(iOS)
        if let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: position) {
            return device
        }
        #endif

        #if os(iOS)
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: position) {
            return device
        }
        #endif

        #if os(macOS)
        if let device = AVCaptureDevice.default(.externalUnknown, for: .video, position: position) {
            return device
        }
        #endif

        if let device = AVCaptureDevice.default(for: .video), device.position == position {
            return device
        }

        return nil
    }
}
