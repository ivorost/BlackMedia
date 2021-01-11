//
//  Network.ACK.swift
//  Capture
//
//  Created by Ivan Kh on 17.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//


import AVFoundation


class VideoViewerACK : DataProcessorImpl {
    
    private var server: DataProcessor?

    init(server: DataProcessor, next: DataProcessor? = nil) {
        self.server = server
        super.init(next: next)
    }
    
    override func process(data: Data) {
        server?.process(data: "next".data(using: .utf8)!)
        super.process(data: data)
    }
}


//class VideoSenderACK : VideoOutputWithNext, DataProcessor {
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

class VideoSenderACK : VideoOutputImpl, DataProcessor {

    private var ready = true
    private var readyTimestamp: Date?
    private var metric: StringProcessorProtocol

    init(next: VideoOutputProtocol?, metric: StringProcessorProtocol) {
        self.metric = metric
        super.init(next: next)
    }
    
    func process(data: Data) {
        if String(data: data, encoding: .utf8) == "next" {
            recover()
        }
    }

    override func process(video: CMSampleBuffer) {
        if let readyTimestamp = readyTimestamp, Date().timeIntervalSince(readyTimestamp) > 1 {
            recover()
        }

        guard ready else { return }

        super.process(video: video)
        ready = false
        readyTimestamp = Date()
    }
    
    private func recover() {
        if let timestamp = readyTimestamp {
            metric.process(string: "\(Date().timeIntervalSince(timestamp))")
        }
        
        ready = true
        readyTimestamp = nil
    }
}


class VideoSetupViewerACK : VideoSetupSlave {
    
    private let server = DataProcessorImpl()

    override func data(_ data: DataProcessor, kind: DataProcessorKind) -> DataProcessor {
        var result = data
        
        if kind == .network {
            server.nextWeak = data
        }

        if kind == .networkData {
            result = VideoViewerACK(server: server, next: result)
        }
        
        return super.data(result, kind: kind)
    }
}


class VideoSetupSenderACK : VideoSetupSenderQuality {
    private let metric: StringProcessorProtocol
    
    init(root: VideoSetupProtocol, metric: StringProcessorProtocol) {
        self.metric = metric
        super.init(root: root)
    }
    
    override func create(next: VideoOutputProtocol) -> VideoOutputProtocol & DataProcessor {
        return VideoSenderACK(next: next, metric: metric)
    }
}

