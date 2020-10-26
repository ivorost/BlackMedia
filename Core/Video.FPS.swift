//
//  Video.FPS.swift
//  Capture
//
//  Created by Ivan Kh on 27.10.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation
import AppKit


fileprivate extension TimeInterval {
    static let blockDuration: TimeInterval = 1.5 // 1.5 second
}


fileprivate extension Int {
    static let maxBlockCount: Int = 5
}


class VideoFPS : VideoOutputProxy {
    private var data = [(framesCount: Double, startDate: Date)]()
    private var callback: FuncWithDouble?
    
    init(callback: @escaping FuncWithDouble, target: VideoOutputProtocol? = nil) {
        self.callback = callback
        super.init(target)
    }
    
    override func process(video: CMSampleBuffer) {
        super.process(video: video)

        if let fps = calcFPS() {
            process(fps: fps)
        }
        
        if data.count >= .maxBlockCount {
            data.removeFirst()
        }
        
        guard let lastData = data.last else {
            startNewBlock()
            return
        }

        if Date().timeIntervalSince(lastData.startDate) > .blockDuration {
            startNewBlock()
            return
        }

        data[data.count-1].framesCount += 1
    }
    
    open func process(fps: Double) {
        callback?(fps)
    }
    
    private func startNewBlock() {
        data.append((framesCount: 1, startDate: Date()))
    }
    
    private func calcFPS() -> Double? {
        guard let firstData = data.first else { return nil }
        
        let startDate = firstData.startDate
        let framesCount = data.map{ $0.framesCount }.reduce(0, +)
        
        return framesCount / Date().timeIntervalSince(startDate)
    }
}
