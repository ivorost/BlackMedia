//
//  AV.Output.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 08.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation

class AssetOutput : SessionProtocol {
    
    private var stopped = false
    private let writer: AVAssetWriter
    private let writerInput: AVAssetWriterInput
    private let writerSession: AssetWriterSession

    init(writer: AVAssetWriter, writerSession: AssetWriterSession, input: AVAssetWriterInput) {
        self.writer = writer
        self.writerInput = input
        self.writerSession = writerSession
    }
    
    func start() throws {
        writerInput.expectsMediaDataInRealTime = true
        writer.add(writerInput)
    }
    
    func stop() {
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


class AssetWriterSession : SessionProtocol {
    
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
    
    func start() throws {
        print("AssetWriterSession.start.a")
        assetWriter.startWriting()
        print("AssetWriterSession.start.z")
    }
    
    func stop() {
        print("AssetWriterSession.stop.a")
        
        print("STOP WRITE A")
        self.finished = true
        self.assetWriter.finishWriting {
            print("STOP WRITE Z")
            print("AssetWriterSession.stop.z")
        }
    }
}

class SizeMonitorSession : NSObject, SessionProtocol, CaptureProgress {
    private let url: URL
    private let interval: TimeInterval
    private var timer: Timer?
    private var startDate = Date()
    private var totalSizeAtStart: Int?
    private var tickFileSize: Int = 0
    private var tickVolumeAvailableCapacity: Int = 0
    private var tickDate: Date?
    
    var secondsSinceStart: TimeInterval {
        return Date().timeIntervalSince(startDate)
    }
    
    var secondsAvailable: TimeInterval? {
        guard let tickDate = tickDate else { return nil }
        
        let secondsSinceStart = tickDate.timeIntervalSince(startDate)
        
        guard secondsSinceStart > 10, tickFileSize > 0, secondsSinceStart > 0 else { return nil }
        
        let sizePerSecond = Double(tickFileSize) / secondsSinceStart
        
        return Double(tickVolumeAvailableCapacity) / sizePerSecond + Date().timeIntervalSince(tickDate)
    }
    
    init(url: URL, interval: TimeInterval) {
        self.url = url
        self.interval = interval
    }
    
    func start() throws {
        DispatchQueue.main.sync {
            timer = Timer.scheduledTimer(timeInterval: interval,
                                         target: self,
                                         selector: #selector(tick),
                                         userInfo: nil,
                                         repeats: true)
        }
        
        startDate = Date()
    }
    
    func stop() {
        DispatchQueue.main.sync {
            timer?.invalidate()
        }
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
