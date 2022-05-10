//
//  Screen.Input.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 21.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//


import AVFoundation


#if os(OSX)
public extension AVCaptureScreenInput {
    convenience init?(settings: Video.ScreenConfig) {
        self.init(displayID: settings.displayID)
        minFrameDuration = settings.fps
        capturesCursor = false
    }
}
#endif

