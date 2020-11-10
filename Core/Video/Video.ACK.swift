//
//  Video.ACK.swift
//  Capture
//
//  Created by Ivan Kh on 10.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation

class VideoACKViewer : DataProcessorImpl {
    
    let server: DataProcessor

    init(server: DataProcessor, next: DataProcessor? = nil) {
        self.server = server
        super.init(next)
    }

    
    override func process(data: Data) {
        server.process(data: "next".data(using: .utf8)!)
        super.process(data: data)
    }
}

class VideoACKHost : VideoOutputImpl, DataProcessor {
    
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
