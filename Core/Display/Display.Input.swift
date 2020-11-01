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
}


class DisplayInput : CaptureInput {
    
    enum Error : Swift.Error {
        case initForDisplay
    }

    private let displayConfig: DisplayConfig
    private let videoConfig: VideoConfig
    
    init(session: AVCaptureSession, display: DisplayConfig, video: VideoConfig) {
        self.displayConfig = display
        self.videoConfig = video
        super.init(session: session)
    }

    override func createInput() throws -> AVCaptureInput {
        if let input = AVCaptureScreenInput(displayID: displayConfig.displayID) {
            input.minFrameDuration = videoConfig.fps
            return input
        }
        else {
            throw Capture.Error.video(Error.initForDisplay)
        }
    }
}
