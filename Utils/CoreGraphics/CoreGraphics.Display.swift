//
//  CoreGraphics.Display.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 09.06.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation

extension AVCaptureScreenInput {
    static var canRecordScreen: Bool {
        let stream = CGDisplayStream(display: CGMainDisplayID(),
                                     outputWidth: 1,
                                     outputHeight: 1,
                                     pixelFormat: Int32(kCVPixelFormatType_32BGRA),
                                     properties: nil,
                                     handler: { status, displayTime, frameSurface, updateRef in
        })
        
        return stream != nil
    }
}
