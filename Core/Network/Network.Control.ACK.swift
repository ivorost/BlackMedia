//
//  Network.ACK.swift
//  Capture
//
//  Created by Ivan Kh on 17.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//


import AVFoundation


class VideoViewerACK : DataProcessorImpl {
    
    private weak var server: DataProcessor?

    init(server: DataProcessor, next: DataProcessor? = nil) {
        self.server = server
        super.init(next: next)
    }
    
    override func process(data: Data) {
        server?.process(data: "next".data(using: .utf8)!)
        super.process(data: data)
    }
}


class VideoSenderACK : VideoOutputWithNext, DataProcessor {
    
    private var ready = true
    private var readyTimestamp: Date?
    
    func process(data: Data) {
        if String(data: data, encoding: .utf8) == "next" {
            ready = true
            readyTimestamp = nil
        }
    }
    
    override func process(video: CMSampleBuffer) {
        if let readyTimestamp = readyTimestamp, Date().timeIntervalSince(readyTimestamp) > 1 {
            self.ready = true
            self.readyTimestamp = nil
        }
        
        guard ready else { return }
        
        super.process(video: video)
        ready = false
        readyTimestamp = Date()
    }
}


class VideoSetupSenderACK : VideoSetupSenderQualityControl<VideoSenderACK> {}


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
