//
//  Screen.Input.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 21.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation
#if os(OSX)
import AppKit
#else
import UIKit
#endif

public struct DisplayConfig : Equatable {
    public static let zero = DisplayConfig(displayID: 0, rect: CGRect.zero, scale: 0, fps: CMTime.zero)
    
    public let displayID: UInt32 // CGDirectDisplayID
    public let rect: CGRect
    public let scale: CGFloat
    public let fps: CMTime

    public init(displayID: UInt32, rect: CGRect, scale: CGFloat, fps: CMTime) {
        self.displayID = displayID
        self.rect = rect
        self.scale = scale
        self.fps = fps
    }
}


public extension DisplayConfig {
    init?(displayID: UInt32, fps: CMTime) {
        var rect = CGRect.zero
        var scale: CGFloat
        #if os(OSX)
        guard let displayMode = CGDisplayCopyDisplayMode(displayID) else { return nil }
        scale = CGFloat(displayMode.pixelWidth / displayMode.width)
        rect.size.width = CGFloat(displayMode.pixelWidth)
        rect.size.height = CGFloat(displayMode.pixelHeight)
        #else
        rect.size.width = UIScreen.main.bounds.width * UIScreen.main.scale
        rect.size.height = UIScreen.main.bounds.height * UIScreen.main.scale
        scale = UIScreen.main.scale
        #endif

        self.init(displayID: displayID, rect: rect, scale: scale, fps: fps)
    }
}


#if os(OSX)
class DisplayInput : CaptureInput {
    
    enum Error : Swift.Error {
        case initForDisplay
    }

    private let settings: DisplayConfig
    
    init(session: AVCaptureSession, settings: DisplayConfig) {
        self.settings = settings
        super.init(session: session)
    }

    override func createInput() throws -> AVCaptureInput {
        if let input = AVCaptureScreenInput(displayID: settings.displayID) {
            input.minFrameDuration = settings.fps
            input.capturesCursor = false
            return input
        }
        else {
            throw Capture.Error.video(Error.initForDisplay)
        }
    }
}
#endif
