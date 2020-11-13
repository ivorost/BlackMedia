//
//  Features.Capture.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 22.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation
import AppKit

class CaptureController : NSViewController {
    enum Error : Swift.Error {
        case unimplemented
    }

    @IBOutlet var previewView: SampleBufferDisplayView?
    @IBOutlet private var captureButton: NSButton!
    @IBOutlet private var listenButton: NSButton!
    @IBOutlet private var stopButton: NSButton!
    @IBOutlet private var errorLabel: NSTextField!
    
    private(set) var activeSession: SessionProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.errorLabel.isHidden = true
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        stop()
    }

    @IBAction private func captureButtonAction(_ sender: Any) {
        capture()
    }

    @IBAction func listenButtonAction(_ sender: Any) {
        listen()
    }

    @IBAction private func stopButtonAction(_ sender: Any) {
        stop()
    }
    
    func authorized() -> Bool? {
        assert(false)
        return false
    }
    
    func requestPermissionsAndWait() {
        assert(false)
    }
    
    func createCaptureSession() throws -> SessionProtocol {
        throw Error.unimplemented
    }

    func createListenSession() throws -> SessionProtocol {
        throw Error.unimplemented
    }

    private func start(createSession: @escaping FuncReturningSessionThrowing) {
        self.stopButton.isEnabled = true
        self.captureButton.isEnabled = false
        self.listenButton.isEnabled = false

        let stop = {
            dispatchMainSync {
                self.stopButton.isEnabled = false
                self.captureButton.isEnabled = true
                self.listenButton.isEnabled = true
            }
        }
        
        DispatchQueue.global().async {
            do {
                self.requestPermissionsAndWait()
                
                if self.authorized() != true {
                    stop()
                    return
                }
                
                var activeSession: SessionProtocol?
                
                try dispatch_sync_on_main {
                    activeSession = Session(try createSession(), start: {}, stop: {
                        stop()
                    })
                    
                    self.activeSession = activeSession
                }

                try activeSession?.start()
            }
            catch {
                logError(error)
                stop()
                self.show(error)
            }
        }
    }
    
    private func capture() {
        start(createSession: createCaptureSession)
    }
    
    private func listen() {
        start(createSession: createListenSession)
    }
    
    func stop() {
        DispatchQueue.global().async {
            let activeSession = self.activeSession
            
            self.activeSession = nil
            activeSession?.stop()
        }
        
        stopButton.isEnabled = false
        captureButton.isEnabled = true
        listenButton.isEnabled = true
    }
    
    private func show(_ error: Swift.Error) {
        var stringValue = error.localizedDescription
        
        if let localizedError = error as? LocalizedError, let failureReason = localizedError.failureReason {
            stringValue += "\n" + failureReason
        }

        if let failureReason = (error as NSError).localizedFailureReason {
            stringValue += "\n" + failureReason
        }

        errorLabel.stringValue = stringValue
        errorLabel.isHidden = false
    }
}
