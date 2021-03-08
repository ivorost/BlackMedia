//
//  Video.Output.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 22.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation

public class VideoCaptureSession : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, SessionProtocol {
    
    private let session: AVCaptureSession
    private let queue: DispatchQueue
    private let output: VideoOutputProtocol?
    private let dataOutput = AVCaptureVideoDataOutput()
    private var lastImageBuffer: CVImageBuffer?
    private var ID: UInt = 0

    public init(session: AVCaptureSession,
         queue: DispatchQueue,
         output: VideoOutputProtocol?) {
        
        self.session = session
        self.queue = queue
        self.output = output
        
        super.init()
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // IOSessionProtocol
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public func start() throws {
//        assert(queue.isCurrent == true)
        logAVPrior("video input start")

        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global())
        dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(Capture.shared.pixelFormat)]
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
//        assert(queue.isCurrent == true)
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // AVCaptureVideoDataOutputSampleBufferDelegate and failure notification
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        logAV("video input \(sampleBuffer.presentationSeconds)")
        
        let ID = self.ID
        self.ID += 1
        self.output?.process(video: VideoBuffer(ID: ID, buffer: sampleBuffer))
    }
    
    func failureNotification(notification: Notification) {
        logAVError("failureNotification " + notification.description)
    }
}
