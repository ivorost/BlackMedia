//
//  Audio.Input.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 08.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation

class AudioInput : NSObject, Session.Proto, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    private let session: AVCaptureSession
    private let device: AVCaptureDevice
    private let queue: DispatchQueue
    private let output: AudioOutputProtocol?
    private let dataOutput = AVCaptureAudioDataOutput()

    init(session: AVCaptureSession,
         device: AVCaptureDevice,
         queue: DispatchQueue,
         output: AudioOutputProtocol?) {
        self.session = session
        self.device = device
        self.queue = queue
        self.output = output
    }
    
    func start() throws {
        print("AudioInput.start.a")
        assert(queue.isCurrent == true)
        let input = try AVCaptureDeviceInput(device: device)
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        else {
            assert(false)
        }
        
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        
        if (session.canAddOutput(dataOutput) == true) {
            session.addOutput(dataOutput)
        }
        print("AudioInput.start.Z")
    }
    
    func stop() {
        assert(queue.isCurrent == true)
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        self.output?.process(audio: sampleBuffer)
    }
}
