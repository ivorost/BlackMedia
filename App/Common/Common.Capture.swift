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

    @IBOutlet private(set) var previewView: SampleBufferDisplayView!
    @IBOutlet private var startButton: NSButton!
    @IBOutlet private var stopButton: NSButton!
    @IBOutlet private var revealInFinderButton: NSButton!
    @IBOutlet private var errorLabel: NSTextField!
    @IBOutlet private var secondsAvailableLabel: NSTextField!
    @IBOutlet private var secondsSinceStartLabel: NSTextField!
    @IBOutlet private var progressView: NSProgressIndicator!
    
    private var captureSession: SessionProtocol?
    private var captureURL: URL?
    private var progressTimer: Timer?
    private var progress: CaptureProgress?
    private let timeFormatter = DateComponentsFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeFormatter.allowedUnits = [.hour, .minute, .second]
        timeFormatter.unitsStyle = .positional
        timeFormatter.zeroFormattingBehavior = [ .pad ]
        
        self.errorLabel.isHidden = true
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        stop()
    }

    @IBAction private func startButtonAction(_ sender: Any) {
        start()
    }

    @IBAction private func stopButtonAction(_ sender: Any) {
        stop()
    }
    
    @IBAction private func revealInFinderButtonAction(_ sender: Any) {
        guard let url = self.captureURL else { assert(false); return }
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }

    func folderURL() -> URL? {
        assert(false)
        return URL.applicationData
    }

    func fileExtension() -> String {
        return "mp4"
    }

    func authorized() -> Bool? {
        assert(false)
        return false
    }
    
    func requestPermissionsAndWait() {
        assert(false)
    }
    
    func createSession(url: URL) throws -> (session: SessionProtocol, progress: CaptureProgress?) {
        throw Error.unimplemented
    }
    
    private func start() {
        self.revealInFinderButton.isEnabled = true
        self.stopButton.isEnabled = true
        self.startButton.isEnabled = false

        let cancel = {
            DispatchQueue.main.sync {
                self.revealInFinderButton.isEnabled = self.captureURL != nil
                self.stopButton.isEnabled = false
                self.startButton.isEnabled = true
            }
        }
        
        DispatchQueue.global().async {
            do {
                let fileName = DateFormatter.fileName.string(from: Date())
                guard let folderURL = self.folderURL() else { assert(false); return }
                let url = folderURL.appendingPathComponent(fileName + "." + self.fileExtension())

                if !FileManager.default.fileExists(atPath: folderURL.path) {
                    try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                }
                
                self.requestPermissionsAndWait()
                
                if self.authorized() != true {
                    cancel()
                    return
                }
                
                var capture: (session: SessionProtocol, progress: CaptureProgress?)?
                
                try DispatchQueue.main.sync {
                    capture = try self.createSession(url: url)
                    
                    self.captureSession = capture?.session
                    self.progress = capture?.progress
                    self.captureURL = url
                }

                try capture?.session.start()

                DispatchQueue.main.sync {
                    self.progressTimer = Timer.scheduledTimer(timeInterval: 1,
                                                              target: self,
                                                              selector: #selector(self.tick),
                                                              userInfo: nil,
                                                              repeats: true)
                }
            }
            catch {
                logError(error)
                cancel()
                self.show(error)
            }
        }
    }
    
    func stop() {
        DispatchQueue.global().async {
            let captureSession = self.captureSession
            
            self.captureSession = nil
            captureSession?.stop()
        }
        
        stopButton.isEnabled = false
        startButton.isEnabled = true
        progressTimer?.invalidate()
        progressTimer = nil
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

    @objc private func tick() {
        guard
            let secondsSinceStart = progress?.secondsSinceStart,
            let secondsSinceStartString = timeFormatter.string(from: secondsSinceStart)
            else { return }

        if
            let secondsAvailable = progress?.secondsAvailable,
            let secondsAvailableString = timeFormatter.string(from: secondsAvailable) {
            secondsAvailableLabel.stringValue = "-" + secondsAvailableString
            progressView.doubleValue = 100.0 * secondsSinceStart / secondsAvailable
        }

        secondsSinceStartLabel.stringValue = secondsSinceStartString
    }
}
