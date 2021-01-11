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

struct DisplayConfig : Equatable {
    static let zero = DisplayConfig(displayID: 0, rect: CGRect.zero, scale: 0, fps: CMTime.zero)
    
    let displayID: UInt32 // CGDirectDisplayID
    let rect: CGRect
    let scale: CGFloat
    let fps: CMTime
}


extension DisplayConfig {
    init?(displayID: UInt32, fps: CMTime) {
        var rect = CGRect.zero
        var scale: CGFloat
        #if os(OSX)
        guard let displayMode = CGDisplayCopyDisplayMode(displayID) else { return nil }
        scale = CGFloat(displayMode.pixelWidth / displayMode.width)
        rect.size.width = CGFloat(displayMode.width)
        rect.size.height = CGFloat(displayMode.width)
        #else
        rect.size.width = UIScreen.main.bounds.width
        rect.size.height = UIScreen.main.bounds.height
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
