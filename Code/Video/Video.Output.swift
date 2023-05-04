//
//  Video.Output.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 22.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif
import AVFoundation
import Accelerate

@available(iOSApplicationExtension, unavailable)
public extension Video {
    class Output : NSObject, Producer.Proto {
        
        public var next: Video.Processor.AnyProto?
        let inner: Capture.Output<AVCaptureVideoDataOutput>
        private let queue: DispatchQueue
        private var ID: UInt = 0
        private var processing = false

        public init(inner: Capture.Output<AVCaptureVideoDataOutput>,
                    queue: DispatchQueue = BlackMedia.Capture.queue,
                    next: Video.Processor.AnyProto = Video.Processor.shared) {

            self.inner = inner
            self.queue = queue
            self.next = next
            
            super.init()
        }
    }
}


@available(iOSApplicationExtension, unavailable)
extension Video.Output : Session.Proto {
    public func start() throws {
        logAVPrior("video input start")

        inner.output.setSampleBufferDelegate(self, queue: queue)
        try inner.start()
        #if canImport(UIKit)
        inner.output.updateOrientationFromInterface()
        #endif
    }
    
    public func stop() {
        inner.output.setSampleBufferDelegate(nil, queue: nil)
        inner.stop()
    }
}

@available(iOSApplicationExtension, unavailable)
extension Video.Output : AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        guard !processing else { return }
        processing = true
//        logAV("video input \(sampleBuffer.presentationSeconds)")
        
        let ID = self.ID
        self.ID += 1

        self.next?.process(Video.Sample(ID: ID, buffer: sampleBuffer))
        processing = false
    }
}

public extension Capture.Output {
    static func video32BGRA(_ session: AVCaptureSession) -> Capture.Output<AVCaptureVideoDataOutput> {
        let result = AVCaptureVideoDataOutput()
        result.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        result.alwaysDiscardsLateVideoFrames = true
        return Capture.Output(output: result, session: session)
    }
}
