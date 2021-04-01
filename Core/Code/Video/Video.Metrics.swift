//
//  Video.FPS.swift
//  Capture
//
//  Created by Ivan Kh on 01.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation
#if os(OSX)
import AppKit
#endif

typealias VideoFPS = VideoProcessor

extension VideoFPS {
    convenience init(_ measure: MeasureProtocol) {
        self.init(next: nil, measure: measure)
    }
}

public class MeasureFPS : MeasureCPS, MeasureProtocol {
    public func begin() {
    }
    
    public func end() {
        measure(count: 1)
    }
}


#if os(OSX)
public class MeasureFPSLabel : MeasureFPS {
    let label: NSTextField

    public init(label: NSTextField) {
        self.label = label
    }
    
    override func process(cps: Double) {
        dispatchMainAsync {
            self.label.stringValue = "\(Int(cps))"
        }
        super.process(cps: cps)
    }
}
#endif

class MeasureVideo : VideoOutputProtocol {
    private let measure: MeasureProtocol
    private let next: VideoOutputProtocol
    
    init(measure: MeasureProtocol, next: VideoOutputProtocol) {
        self.measure = measure
        self.next = next
    }
    
    func process(video: VideoBuffer) {
        measure.begin()
        next.process(video: video)
        measure.end()
    }
}


public class VideoOutputPresentationTime : VideoOutputProtocol {
    private let string: StringProcessor.Proto
    private let timebase: Timebase
    private var startTime: Double?
    private let lock = NSLock()
    
    public init(string: StringProcessor.Proto, timebase: Timebase) {
        self.string = string
        self.timebase = timebase
    }
    
    public func process(video: VideoBuffer) {
        lock.locked {
            if startTime == nil {
                startTime = video.sampleBuffer.presentationSeconds
            }
            
            if let startTime = startTime {
                let clock = "\(Date().timeIntervalSince(timebase.date))"
                    .padding(toLength: 10, withPad: " ", startingAt: 0)
                let presentation = "\(video.sampleBuffer.presentationSeconds - startTime)"
                
                string.process(string: "\(clock) : \(presentation)")
            }
        }
    }
}


public class VideoSetupMeasure : VideoSetup {
    let kind: VideoProcessor.Kind
    let measure: MeasureProtocol
    
    public init(kind: VideoProcessor.Kind, measure: MeasureProtocol) {
        self.kind = kind
        self.measure = measure
    }
    
    public override func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        var result = video
        
        if kind == self.kind {
            result = VideoProcessor(prev: result, measure: measure)
        }
        
        return result
    }
}

public class VideoPresentationDelay : VideoH264DeserializerBase, VideoOutputProtocol {
    private let next: StringProcessor.Proto
    private var output = [Int64 : VideoTime]()
    
    public init(next: StringProcessor.Proto) {
        self.next = next
        super.init(metadataOnly: true)
    }
    
    public override func process(metadata: VideoProcessor.Packet) {
        output[metadata.time.timestamp.timeStamp] = metadata.originalTime
    }

    public func process(video: VideoBuffer) {
        let key = CMSampleBufferGetPresentationTimeStamp(video.sampleBuffer).value
        guard let originalTimeSeconds = output[key]?.timestamp.seconds
        else { assert(false); return }
        let currentTimeSeconds = CACurrentMediaTime();
        let delta = currentTimeSeconds - originalTimeSeconds

        output.removeValue(forKey: key)
        next.process(string: "\(delta)")
    }
}
