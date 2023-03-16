//
//  Camera.QR.swift
//  Core
//
//  Created by Ivan Kh on 31.03.2023.
//

import AVFoundation

@available(iOSApplicationExtension, unavailable)
public extension Video {
    static func scanQR(video: Video.Processor.AnyProto, string: String.Processor.AnyProto) -> Session.Proto {
        guard let avInput = AVCaptureDeviceInput.rearCamera else { return Session.shared }
        let avCaptureSession = AVCaptureSession()
        let input = Capture.Input(session: avCaptureSession, input: avInput)
        let videoOutput = Output(inner: .video32BGRA(avCaptureSession))
        let metadataOutput = StringMetadataOutput.qr(avCaptureSession)

        videoOutput
            .next(video)

        metadataOutput
            .next(string)

        return broadcast([ input, metadataOutput, videoOutput, avCaptureSession ])
    }
}
