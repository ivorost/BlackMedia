//
//  Video.Output.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 22.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation
import UIKit

@available(iOSApplicationExtension, unavailable)
public extension Video {
    class CaptureSession : NSObject {
        
        let dataOutput = AVCaptureVideoDataOutput()
        private let session: AVCaptureSession
        private let queue: DispatchQueue
        private let output: Video.Processor.Proto?
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


@available(iOSApplicationExtension, unavailable)
extension Video.CaptureSession : Session.Proto {
    public func start() throws {
        assert(queue.isCurrent == true)
        logAVPrior("video input start")

        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(Video.defaultPixelFormat)]
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if (session.canAddOutput(dataOutput) == true) {
            session.addOutput(dataOutput)
            dataOutput.updateOrientationFromInterface()
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


@available(iOSApplicationExtension, unavailable)
extension Video.CaptureSession : AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        logAV("video input \(sampleBuffer.presentationSeconds)")
        
        let ID = self.ID
        self.ID += 1

        self.output?.process(video: Video.Sample(ID: ID, buffer: sampleBuffer))
    }
}
