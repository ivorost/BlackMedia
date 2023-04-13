//
//  Video.Output.Metadata.swift
//  Core
//
//  Created by Ivan Kh on 31.03.2023.
//

import AVFoundation
import BlackUtils

@available(iOSApplicationExtension, unavailable)
@available(macOS 13.0, *)
public extension Video {
    class StringMetadataOutput : NSObject, ProducerProtocol {
        public var next: String.Processor.AnyProto?
        private var inner: Capture.Output<AVCaptureMetadataOutput>
        private let metadata: AVMetadataObject.ObjectType

        public init(session: AVCaptureSession, metadata: AVMetadataObject.ObjectType) {
            self.inner = Capture.Output(output: AVCaptureMetadataOutput(), session: session)
            self.metadata = metadata
            super.init()
        }
    }
}

@available(iOSApplicationExtension, unavailable)
@available(macOS 13.0, *)
extension Video.StringMetadataOutput: Session.Proto {
    public func start() throws {
        inner.output.setMetadataObjectsDelegate(self, queue: .main)
        try inner.start()

        if inner.output.availableMetadataObjectTypes.contains(metadata) {
            inner.output.metadataObjectTypes = [metadata]
        }
        else {
            logError(Error.unsupportedMetadata(metadata))
        }
    }

    public func stop() {
        inner.stop()
    }
}

@available(iOSApplicationExtension, unavailable)
@available(macOS 13.0, *)
extension Video.StringMetadataOutput: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            next?.process(stringValue)
        }
    }
}

@available(iOSApplicationExtension, unavailable)
@available(macOS 13.0, *)
public extension Video.StringMetadataOutput {
    enum Error: Swift.Error {
        case unsupportedMetadata(AVMetadataObject.ObjectType)
    }
}

@available(iOSApplicationExtension, unavailable)
@available(macOS 13.0, *)
extension Video.StringMetadataOutput {
    static func qr(_ session: AVCaptureSession) -> Video.StringMetadataOutput {
        return Video.StringMetadataOutput(session: session, metadata: .qr)
    }
}
