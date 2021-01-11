//
//  Network.ACK.swift
//  Capture
//
//  Created by Ivan Kh on 17.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//


import AVFoundation


class VideoViewerACK : DataProcessor {
    
    private var server: DataProcessorProtocol?

    init(server: DataProcessorProtocol, next: DataProcessorProtocol? = nil) {
        self.server = server
        super.init(next: next)
    }
    
    override func process(data: Data) {
        let packet = PacketDeserializer(data)
        
        if packet.type == .video {
            server?.process(data: "ack \(data.count)".data(using: .utf8)!)
        }
        
        super.process(data: data)
    }
}


//class VideoSenderACK : VideoOutputWithNext, DataProcessorProtocol {
//    private var counter = 10
//
//    func process(data: Data) {
//    }
//
//    override func process(video: CMSampleBuffer) {
//        if counter >= 10 {
//            counter = 0
//            super.process(video: video)
//        }
//        else {
//            counter += 1
//        }
//    }
//}

class VideoSenderACKCapture : VideoProcessor, DataProcessorProtocol {

    private var queue = Set<Int>()
    private var readyTimestamp: Date?
    private var metric: StringProcessorProtocol
    private let lock = NSRecursiveLock()
    private var lastSampleBuffer: CMSampleBuffer?

    init(next: VideoOutputProtocol?, metric: StringProcessorProtocol) {
        self.metric = metric
        super.init(next: next)
    }
    
    override func process(video: CMSampleBuffer) {
        if let readyTimestamp = readyTimestamp, Date().timeIntervalSince(readyTimestamp) > 3 {
            recover()
        }

        let count = lock.locked { queue.count }
        
        if count == 0 {
            super.process(video: video)
            lock.locked { readyTimestamp = Date() }
        }
        else {
            lock.locked { lastSampleBuffer = video }
        }
    }
    
    func process(data: Data) {
        guard let string = String(data: data, encoding: .utf8), string.hasPrefix("ack ") else { return }
        let sizeString = string.suffix(from: string.index(string.startIndex, offsetBy: 4))
        
        if let size = Int(sizeString) {
            lock.locked {
                queue.remove(size)
                
                if queue.count == 0 {
                    recover()
                }
            }
        }
        else {
            assert(false)
        }
    }

    func wait(size: Int) {
        _ = lock.locked {
            queue.insert(size)
        }
    }
    
    private func recover() {
        if let timestamp = readyTimestamp {
            metric.process(string: "\(Date().timeIntervalSince(timestamp))")
        }
        
        lock.locked {
            queue.removeAll()
        }
        
        readyTimestamp = nil
        
        if let sampleBuffer = lastSampleBuffer {
            process(video: sampleBuffer)
        }
    }
}


class VideoSenderACKNetwork : DataProcessorProtocol {
    fileprivate weak var capture: VideoSenderACKCapture?
    
    func process(data: Data) {
        guard PacketDeserializer(data).type == .video else { return }
        capture?.wait(size: data.count)
    }
}


class VideoSetupViewerACK : VideoSetupSlave {
    
    private let server = DataProcessor()

    override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        var result = data
        
        if kind == .networkHelm {
            server.nextWeak = data
        }

        if kind == .networkDataOutput {
            result = VideoViewerACK(server: server, next: result)
        }
        
        return super.data(result, kind: kind)
    }
}


class VideoSetupSenderACK : VideoSetupSenderQuality {
    private let metric: StringProcessorProtocol
    private var network: VideoSenderACKNetwork?
    
    init(root: VideoSetupProtocol, metric: StringProcessorProtocol) {
        self.metric = metric
        super.init(root: root)
    }

    override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        var result = data
        
        if kind == .networkData {
            let ack = VideoSenderACKNetwork()
            network = ack
            result = DataProcessor(prev: ack, next: result)
        }
        
        return super.data(result, kind: kind)
    }
    
    override func create(next: VideoOutputProtocol) -> VideoOutputProtocol & DataProcessorProtocol {
        assert(network != nil)
        
        let result = VideoSenderACKCapture(next: next, metric: metric)
        network?.capture = result
        return result
    }
}

//class VideoSetupSenderACK : VideoSetupSenderQuality {
//    private let metric: StringProcessorProtocol
//
//    init(root: VideoSetupProtocol, metric: StringProcessorProtocol) {
//        self.metric = metric
//        super.init(root: root)
//    }
//
//    override func create(next: VideoOutputProtocol) -> VideoOutputProtocol & DataProcessorProtocol {
//        return VideoSenderACK(next: next, metric: metric)
//    }
//}

