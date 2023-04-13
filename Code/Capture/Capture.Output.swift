//
//  AV.Output.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 08.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation
import BlackUtils

public extension Capture {
    class Output<TCaptureOutput>: Session.Proto where TCaptureOutput: AVCaptureOutput {
        let output: TCaptureOutput
        let session: AVCaptureSession

        init(output: TCaptureOutput, session: AVCaptureSession) {
            self.output = output
            self.session = session
        }

        public func start() throws {
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            else {
                logError(Error.unableToAddOutput(output))
            }
        }
        
        public func stop() {
            session.removeOutput(output)
        }
    }
}

public extension Capture.Output {
    enum Error: Swift.Error {
        case unableToAddOutput(AVCaptureOutput)
    }
}

public extension Capture {
    class AssetOutput : Session.Proto {
        
        private var stopped = false
        private let writer: AVAssetWriter
        private let writerInput: AVAssetWriterInput
        private let writerSession: AssetWriterSession

        init(writer: AVAssetWriter, writerSession: AssetWriterSession, input: AVAssetWriterInput) {
            self.writer = writer
            self.writerInput = input
            self.writerSession = writerSession
        }
        
        public func start() throws {
            writerInput.expectsMediaDataInRealTime = true
            writer.add(writerInput)
        }
        
        public func stop() {
    //        stopped = true
        }
        
        func process(sampleBuffer: CMSampleBuffer) {
            guard !writerSession.finished else { return }
            
            writerSession.start(sampleBuffer: sampleBuffer)
            
            if writerInput.isReadyForMoreMediaData {
                append(sampleBuffer: sampleBuffer)
            }
        }
        
        func append(sampleBuffer: CMSampleBuffer) {
            writerInput.append(sampleBuffer)
        }
    }
}


public extension Capture {
    class AssetWriterSession : Session.Proto {
        
        private let assetWriter: AVAssetWriter
        private var sessionStarted = false
        public var finished = false
        
        init(asset: AVAssetWriter) {
            self.assetWriter = asset
        }
        
        func start(sampleBuffer: CMSampleBuffer) {
            guard !sessionStarted else { return }
            
            print("AssetWriterSession.start.sampleBuffer.a")
            assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            sessionStarted = true
            print("AssetWriterSession.start.sampleBuffer.z")
        }
        
        public func start() throws {
            print("AssetWriterSession.start.a")
            assetWriter.startWriting()
            print("AssetWriterSession.start.z")
        }
        
        public func stop() {
            print("AssetWriterSession.stop.a")
            
            print("STOP WRITE A")
            self.finished = true
            self.assetWriter.finishWriting {
                print("STOP WRITE Z")
                print("AssetWriterSession.stop.z")
            }
        }
    }
}


public extension Capture {
    class SizeMonitorSession : NSObject {
        private let url: URL
        private let interval: TimeInterval
        private var timer: Timer?
        private var startDate = Date()
        private var totalSizeAtStart: Int?
        private var tickFileSize: Int = 0
        private var tickVolumeAvailableCapacity: Int = 0
        private var tickDate: Date?
                
        init(url: URL, interval: TimeInterval) {
            self.url = url
            self.interval = interval
        }
        
        @objc private func tick() {
            guard
                let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey,
                                                                       .totalFileSizeKey,
                                                                       .volumeAvailableCapacityKey]),
                let fileSize = resourceValues.fileSize,
                let volumeAvailableCapacity = resourceValues.volumeAvailableCapacity
            else { assert(false); return }
            
            tickDate = Date()
            tickFileSize = fileSize
            tickVolumeAvailableCapacity = volumeAvailableCapacity
        }
    }
}


extension Capture.SizeMonitorSession : Session.Proto {
    public func start() throws {
        DispatchQueue.main.sync {
            timer = Timer.scheduledTimer(timeInterval: interval,
                                         target: self,
                                         selector: #selector(tick),
                                         userInfo: nil,
                                         repeats: true)
        }
        
        startDate = Date()
    }
    
    public func stop() {
        DispatchQueue.main.sync {
            timer?.invalidate()
        }
    }
}


extension Capture.SizeMonitorSession : CaptureProgress {
    public var secondsSinceStart: TimeInterval {
        return Date().timeIntervalSince(startDate)
    }
    
    public var secondsAvailable: TimeInterval? {
        guard let tickDate = tickDate else { return nil }
        
        let secondsSinceStart = tickDate.timeIntervalSince(startDate)
        
        guard secondsSinceStart > 10, tickFileSize > 0, secondsSinceStart > 0 else { return nil }
        
        let sizePerSecond = Double(tickFileSize) / secondsSinceStart
        
        return Double(tickVolumeAvailableCapacity) / sizePerSecond + Date().timeIntervalSince(tickDate)
    }
}
