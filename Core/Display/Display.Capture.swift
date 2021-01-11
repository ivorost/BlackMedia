//
//  Screen.Capture.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 22.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//


import AVFoundation


class DisplayCapture {
    
}

class DisplaySetup : VideoSetupSlave {
    #if os(OSX)
    private let settings: DisplayConfig
    private let avCaptureSession = AVCaptureSession()
    
    init(root: VideoSetupProtocol, settings: DisplayConfig) {
        self.settings = settings
        super.init(root: root)
    }
    
    override func session(_ session: Session.Proto, kind: Session.Kind) {
        if kind == .initial {
            let video = root.video(VideoProcessor(), kind: .capture)
            
            setupSession(avCaptureSession)
            root.session(input(), kind: .input)
            root.session(capture(next: video), kind: .capture)
            root.session(avCaptureSession, kind: .avCapture)
        }
    }
    
    func input() -> DisplayInput {
        return DisplayInput(session: avCaptureSession,
                            settings: settings)
    }
    
    func capture(next: VideoOutputProtocol) -> VideoCaptureSession {
        return VideoCaptureSession(session: avCaptureSession,
                                   queue: Capture.shared.captureQueue,
                                   output: next)
    }
    
    func setupSession(_ session: AVCaptureSession) {
        session.sessionPreset = .high
    }
    #endif
}
