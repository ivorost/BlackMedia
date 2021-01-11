//
//  Video.FPS.swift
//  Capture
//
//  Created by Ivan Kh on 01.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation
import AppKit

typealias VideoFPS = VideoProcessor

extension VideoFPS {
    convenience init(_ measure: MeasureProtocol) {
        self.init(next: nil, measure: measure)
    }
}

class MeasureFPS : MeasureCPS, MeasureProtocol {
    func begin() {
    }
    
    func end() {
        measure(count: 1)
    }
}


class MeasureFPSPrint : MeasureFPS {
    
    let title: String
    
    init(title: String, callback: @escaping FuncWithDouble) {
        self.title = title
        super.init(callback: callback)
    }
    
    override func process(cps: Double) {
        print("\(title) \(cps)")
        super.process(cps: cps)
    }
}


class MeasureFPSLabel : MeasureFPS {
    let label: NSTextField

    init(label: NSTextField) {
        self.label = label
        super.init { _ in }
    }
    
    override func process(cps: Double) {
        dispatchMainAsync {
            self.label.stringValue = "\(Int(cps))"
        }
        super.process(cps: cps)
    }
}


class MeasureVideo : VideoOutputProtocol {
    private let measure: MeasureProtocol
    private let next: VideoOutputProtocol
    
    init(measure: MeasureProtocol, next: VideoOutputProtocol) {
        self.measure = measure
        self.next = next
    }
    
    func process(video: CMSampleBuffer) {
        measure.begin()
        next.process(video: video)
        measure.end()
    }
}


class VideoOutputPresentationTime : VideoOutputProtocol {
    let string: StringProcessorProtocol
    let timebase: Timebase
    var startTime: Double?
    
    init(string: StringProcessorProtocol, timebase: Timebase) {
        self.string = string
        self.timebase = timebase
    }
        
    func process(video: CMSampleBuffer) {
        if startTime == nil {
            startTime = video.presentationSeconds
        }
        
        if let startTime = startTime {
            let clock = "\(Date().timeIntervalSince(timebase.date))".padding(toLength: 10, withPad: " ", startingAt: 0)
            let presentation = "\(video.presentationSeconds - startTime)"
            string.process(string: "\(clock) : \(presentation)")
        }
    }
}


class VideoSetupMeasure : VideoSetup {
    let kind: VideoProcessor.Kind
    let measure: MeasureProtocol
    
    init(kind: VideoProcessor.Kind, measure: MeasureProtocol) {
        self.kind = kind
        self.measure = measure
    }
    
    override func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        var result = video
        
        if kind == self.kind {
            result = VideoProcessor(prev: result, measure: measure)
        }
        
        return result
    }
}

class VideoPresentationDelay : VideoH264DeserializerBase, VideoOutputProtocol {
    private let next: StringProcessorProtocol
    private var output = [Int64 : VideoTime]()
    
    init(next: StringProcessorProtocol) {
        self.next = next
        super.init(metadataOnly: true)
    }
    
    override func process(time: VideoTime, originalTime: VideoTime) {
        output[time.timestamp.timeStamp] = originalTime
    }

    func process(video: CMSampleBuffer) {
        let key = CMSampleBufferGetPresentationTimeStamp(video).value
        guard let originalTimeSeconds = output[key]?.timestamp.seconds
        else { assert(false); return }
        let currentTimeSeconds = CACurrentMediaTime();
        let delta = currentTimeSeconds - originalTimeSeconds

        output.removeValue(forKey: key)
        next.process(string: "\(delta)")
    }
}
