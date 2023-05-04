//
//  Camera.QR.swift
//  Core
//
//  Created by Ivan Kh on 31.03.2023.
//

import AVFoundation

@available(iOSApplicationExtension, unavailable)
@available(macOS 13.0, *)
public extension Video {
    static func scanQR(video: Video.Processor.AnyProto, string: String.Processor.AnyProto) -> Session.Proto {
        guard let avInput = AVCaptureDeviceInput.rearCamera else { return Session.shared }
        let session = Capture.Session()
        let input = Capture.Input(session: session.inner, input: avInput)
        let videoOutput = Output(inner: .video32BGRA(session.inner))
        let metadataOutput = StringMetadataOutput.qr(session.inner)

        videoOutput
            .next(video)

        metadataOutput
            .next(string)

        return broadcast([ input, metadataOutput, videoOutput, session ])
    }
}
