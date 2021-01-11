//
//  Network.ACK.swift
//  Capture
//
//  Created by Ivan Kh on 17.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//


import AVFoundation


class VideoViewerACK : VideoH264DeserializerBase {
    fileprivate var server: DataProcessorProtocol?

    init(server: DataProcessorProtocol?) {
        self.server = server
        super.init(metadataOnly: true)
    }

    override func process(metadata: VideoProcessor.Packet) {
        server?.process(data: "ack \(metadata.ID)".data(using: .utf8)!)
    }
}


class VideoSenderACKCapture : VideoProcessor, DataProcessor.Proto, Flushable.Proto {

    private var queue = [(ID: UInt, timestamp: Date)]()
    private var metric: StringProcessor.Proto
    private let lock = NSRecursiveLock()
    private var lastVideoBuffer: VideoBuffer?
    private var processTimeStamp: Date?
    private let timebase: Timebase

    init(next: VideoOutputProtocol, timebase: Timebase, metric: StringProcessor.Proto) {
        self.timebase = timebase
        self.metric = metric
        super.init(next: next)
    }
    
    override func process(video: VideoBuffer) {
        var process = false
        
        lock.locked {
            flushState()
            
            if queue.count < 2 {
                process = true
                queue.append((ID: video.ID, timestamp: Date()))
                self.processTimeStamp = Date()
            }
        }
        
        if process {
            super.process(video: video)
        }
    }
    
    func process(data: Data) {
        guard let string = String(data: data, encoding: .utf8), string.hasPrefix("ack ") else { return }
        let idString = string.suffix(from: string.index(string.startIndex, offsetBy: 4))
        
        if let ID = UInt(idString) {
            lock.locked {
                if let removed = queue.removeFirst(where: { $0.ID == ID }) {
                    metric(ID: removed.ID, timestamp: queue.last?.timestamp ?? removed.timestamp)
                }

                flush()
            }
        }
        else {
            assert(false)
        }
    }
    
    private func flushState() {
        lock.locked {
            var flush = false
            
            if !flush, processTimeStamp == nil {
                flush = true
            }

            if !flush, let timestamp = processTimeStamp, Date().timeIntervalSince(timestamp) > 3 {
                flush = true
            }
            
            if flush && queue.count > 0 {
                let removed = queue.removeFirst()
                metric(ID: removed.ID, timestamp: queue.last?.timestamp ?? removed.timestamp, comment: "(timeout)")
            }
        }
    }
    
    func flush() {
        var lastVideoBuffer: VideoBuffer?
        
        lock.locked {
            lastVideoBuffer = self.lastVideoBuffer
            self.lastVideoBuffer = nil
        }
        
        if let lastVideoBuffer = lastVideoBuffer {
            process(video: lastVideoBuffer)
            
        }
    }

    private func metric(ID: UInt, timestamp: Date, comment: String = "") {
        let idString = "ID \(ID)".padding(toLength: 9, withPad: " ", startingAt: 0)
        let timeString = String(format: "duration %.2f", Date().timeIntervalSince(timestamp))
        metric("\(idString) \(timeString) \(comment)")
    }
    
    private func metric(_ string: String) {
        let time = String(format: "[%.2f]", Date().timeIntervalSince(timebase.date))
            .padding(toLength: 9, withPad: " ", startingAt: 0)
        
        metric.process(string: "\(time) \(string)")
    }
}


class VideoSetupViewerACK : VideoSetupSlave {
    private var server: DataProcessor.Proto?
    private var ack: VideoViewerACK?

    override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        var result = data
        
        if kind == .networkHelm {
            server = data
            ack?.server = server
        }

        if kind == .networkDataOutput {
            let ack = VideoViewerACK(server: server)
            self.ack = ack
            result = DataProcessor(prev: result, next: ack)
        }
        
        return super.data(result, kind: kind)
    }
}


class VideoSetupSenderACK : VideoSetupSenderQuality {
    private let timebase: Timebase
    private let metric: StringProcessor.Proto

    init(root: VideoSetupProtocol, timebase: Timebase, metric: StringProcessor.Proto = StringProcessor.shared) {
        self.timebase = timebase
        self.metric = metric
        super.init(root: root)
    }

    override func create(next: VideoOutputProtocol) -> VideoOutputProtocol & DataProcessorProtocol {
        return VideoSenderACKCapture(next: next, timebase: timebase, metric: metric)
    }
}
