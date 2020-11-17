//
//  Screen.Input.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 21.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation


struct DisplayConfig : Equatable {
    let displayID: CGDirectDisplayID
    let rect: CGRect
    let fps: CMTime
}


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
            return input
        }
        else {
            throw Capture.Error.video(Error.initForDisplay)
        }
    }
}
