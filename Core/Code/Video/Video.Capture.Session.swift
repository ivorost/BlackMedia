//
//  Video.Output.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 22.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation


public extension Video {
    class CaptureSession : NSObject {
        
        private let session: AVCaptureSession
        private let queue: DispatchQueue
        private let output: Video.Processor.Proto?
        private let dataOutput = AVCaptureVideoDataOutput()
        private var lastImageBuffer: CVImageBuffer?
        private var ID: UInt = 0

        public init(session: AVCaptureSession, queue: DispatchQueue, output: Video.Processor.Proto?) {
            
            self.session = session
            self.queue = queue
            self.output = output
            
            super.init()
        }
    }
}


extension Video.CaptureSession : Session.Proto {
    public func start() throws {
        assert(queue.isCurrent == true)
        logAVPrior("video input start")

        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(Video.defaultPixelFormat)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if (session.canAddOutput(dataOutput) == true) {
            session.addOutput(dataOutput)
        }
        else {
            assert(false)
        }

        NotificationCenter.default.addObserver(
            forName: .AVSampleBufferDisplayLayerFailedToDecode,
            object: nil,
            queue: nil,
            using: failureNotification)
    }
    
    public func stop() {
        assert(queue.isCurrent == true)
    }
    
    private func failureNotification(notification: Notification) {
        logAVError("failureNotification " + notification.description)
    }
}


extension Video.CaptureSession : AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        logAV("video input \(sampleBuffer.presentationSeconds)")
        
        let ID = self.ID
        self.ID += 1
        self.output?.process(video: Video.Buffer(ID: ID, buffer: sampleBuffer))
    }
}
