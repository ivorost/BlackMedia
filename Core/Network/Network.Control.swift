//
//  Network.Quality.swift
//  Capture
//
//  Created by Ivan Kh on 17.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation


extension Double {
    static let maxGap = 0.5
}


class VideoViewerQuality : VideoOutputImpl {
    var bestSample: Double?
    var localTime: Date?
    var slowing = false
    let server: DataProcessor
    
    init(server: DataProcessor, next: VideoOutputProtocol? = nil) {
        self.server = server
        super.init(next: next)
    }
    
    override func process(video: CMSampleBuffer) {
        let sampleTime = video.presentationSeconds
        var gap = 0.0
        
        super.process(video: video)

        if let bestSample = bestSample, let localTime = localTime {
            let sampleDiff = sampleTime - bestSample
            let localDiff = Date().timeIntervalSince(localTime)
            
            gap = localDiff - sampleDiff
            print("lag \(gap)")
        }
        
        if bestSample == nil || gap < -1 {
            bestSample = sampleTime
            localTime = Date()
        }

        if gap > .maxGap && slowing == false {
            slowing = true
            server.process(data: "easy".data(using: .utf8)!)
        }
        
        if gap < .maxGap && slowing == true {
            slowing = false
            server.process(data: "hard".data(using: .utf8)!)
        }

        super.process(video: video)
    }
}


class VideoSenderQuality : VideoOutputImpl, DataProcessor {
    
    private var slowing = false
    private var lastFrameSent: Date?
    
    override func process(video: CMSampleBuffer) {
        if slowing {
            if let lastFrameSent = lastFrameSent, Date().timeIntervalSince(lastFrameSent) > 1.0 {
                super.process(video: video)
                self.lastFrameSent = Date()
            }

            if lastFrameSent == nil {
                lastFrameSent = Date()
            }
        }
        else {
            super.process(video: video)
        }
    }
    
    func process(data: Data) {
        let message = String(data: data, encoding: .utf8)
        
        if message == "easy" {
            slowing = true
        }
        else if message == "hard" {
            slowing = false
        }
    }
}


class VideoSetupSenderQuality : VideoSetupSlave {
    private var networkSenderListener: DataProcessorImpl?

    override func video(_ video: VideoOutputProtocol, kind: VideoOutputKind) -> VideoOutputProtocol {
        var result = video
        
        if kind == .capture {
            let control = create(next: result)
            networkSenderListener?.nextWeak = control
            result = control
        }
        
        return super.video(result, kind: kind)
    }
    
    override func data(_ data: DataProcessor, kind: DataProcessorKind) -> DataProcessor {
        var result = data
        
        if kind == .networkData {
            let networkSenderListener = DataProcessorImpl(prev: result)
            
            self.networkSenderListener = networkSenderListener
            result = networkSenderListener
        }
        
        return super.data(result, kind: kind)
    }
    
    func create(next: VideoOutputProtocol) -> VideoOutputProtocol & DataProcessor {
        return VideoSenderQuality(next: next)
    }
}


class VideoSetupViewerQualityControl : VideoSetupSlave {
    private let server = DataProcessorImpl()
    
    override func video(_ video: VideoOutputProtocol, kind: VideoOutputKind) -> VideoOutputProtocol {
        var result = video
        
        if kind == .deserializer {
            result = VideoViewerQuality(server: server, next: result)
        }
        
        return super.video(result, kind: kind)
    }
    
    override func data(_ data: DataProcessor, kind: DataProcessorKind) -> DataProcessor {
        if kind == .network {
            server.nextWeak = data
        }
        
        return super.data(data, kind: kind)
    }
}
