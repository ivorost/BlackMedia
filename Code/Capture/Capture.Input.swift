//
//  AV.Input.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 22.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation


public extension Capture {
    class Input : NSObject, BlackMedia.Session.Proto {
        
        enum Error : Swift.Error {
            case unimplemented
            case addInput
        }

        public let session: AVCaptureSession
        public let input: AVCaptureInput

        init(session: AVCaptureSession, input: AVCaptureInput) {
            self.session = session
            self.input = input
        }
        
        public func start() throws {
            guard session.canAddInput(input) else { throw Capture.Error.video(Error.addInput) }
            #if os(iOS)
            session.sessionPreset = .inputPriority
            #endif
            session.addInput(input)
        }
        
        public func stop() {
            session.removeInput(input)
        }
    }
}


public extension Capture {
    class DeviceInput : Input {
        public let deviceInput: AVCaptureDeviceInput
        public let format: AVCaptureDevice.Format

        init(session: AVCaptureSession,
             input: AVCaptureDeviceInput,
             format: AVCaptureDevice.Format) {
            self.deviceInput = input
            self.format = format
            super.init(session: session, input: input)
        }
        
        public override func start() throws {
            do {
                try deviceInput.device.lockForConfiguration()
                deviceInput.device.activeFormat = format
                self.deviceInput.device.unlockForConfiguration()
            }
            catch {
                self.deviceInput.device.unlockForConfiguration()
                throw error
            }

            try super.start()
        }
    }
}


public extension Capture {
    class DeviceInputConfiguration : BlackMedia.Session.Proto {
        public typealias Func = (DeviceInput) -> Void
        private let input: DeviceInput
        private let configure: Func?

        init(input: DeviceInput, configure: Func?) {
            self.input = input
            self.configure = configure
        }
        
        public func start() throws {
            do {
                try input.deviceInput.device.lockForConfiguration()
                configure?(input)
                input.deviceInput.device.unlockForConfiguration()
            }
            catch {
                input.deviceInput.device.unlockForConfiguration()
                throw error
            }
        }
        
        public func stop() {
        }
    }
}
