//
//  Camera.Capture.swift
//  Core
//
//  Created by Ivan Kh on 15.04.2022.
//

import AVFoundation


extension Video.Setup.DeviceInput {
    static func rearCamera(root: Video.Setup.Proto,
                           input: AVCaptureDeviceInput,
                           format: AVCaptureDevice.Format) -> Video.Setup.DeviceInput {

        return Video.Setup.DeviceInput(root: root, session: AVCaptureSession(), input: input, format: format) { _ in
            input.device.activeVideoMinFrameDuration = format.videoSupportedFrameRateRanges[0].maxFrameDuration
            input.device.activeVideoMaxFrameDuration = format.videoSupportedFrameRateRanges[0].maxFrameDuration
        }
    }
}
