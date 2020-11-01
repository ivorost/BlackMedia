//
//  AV.Input.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 22.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation


class CaptureInput : NSObject, SessionProtocol {
    
    enum Error : Swift.Error {
        case unimplemented
        case addInput
    }

    private let session: AVCaptureSession
    private var input: AVCaptureInput?
    
    init(session: AVCaptureSession) {
        self.session = session
    }

    func createInput() throws -> AVCaptureInput {
        throw Error.unimplemented
    }
    
    func start() throws {
        let input = try createInput()
        
        guard
            session.canAddInput(input)
            else { throw Capture.Error.video(Error.addInput) }

        self.input = input

        if session.canAddInput(input) {
            session.addInput(input)
        }
        else {
            assert(false)
        }
    }
    
    func stop() {
        if let input = input {
            session.removeInput(input)
        }
        
        input = nil
    }
}
