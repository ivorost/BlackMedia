//
//  Video.FPS.swift
//  Capture
//
//  Created by Ivan Kh on 01.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation


extension Video {
    class Measure : Processor.Proto {
        private let measure: MeasureProtocol
        private let next: Processor.Proto
        
        init(measure: MeasureProtocol, next: Processor.Proto) {
            self.measure = measure
            self.next = next
        }
        
        func process(video: Buffer) {
            measure.begin()
            next.process(video: video)
            measure.end()
        }
    }
}


public extension Video.Processor {
    class OutputPresentationTime : Proto {
        private let string: String.Processor.Proto
        private let timebase: Capture.Timebase
        private var startTime: Double?
        private let lock = NSLock()
        
        public init(string: String.Processor.Proto, timebase: Capture.Timebase) {
            self.string = string
            self.timebase = timebase
        }
        
        public func process(video: Video.Buffer) {
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
}


public extension Video.Setup {
    class Measure : Base {
        let kind: Video.Processor.Kind
        let measure: MeasureProtocol
        
        public init(kind: Video.Processor.Kind, measure: MeasureProtocol) {
            self.kind = kind
            self.measure = measure
        }
        
        public override func video(_ video: Video.Processor.Proto, kind: Video.Processor.Kind) -> Video.Processor.Proto {
            var result = video
            
            if kind == self.kind {
                result = Video.Processor.Base(prev: result, measure: measure)
            }
            
            return result
        }
    }
}


public extension Video.Processor {
    class PresentationDelay : Data.Processor.DeserializerH264Base, Proto {
        private let next: String.Processor.Proto
        private var output = [Int64 : Video.Time]()
        
        public init(next: String.Processor.Proto) {
            self.next = next
            super.init(metadataOnly: true)
        }
        
        public override func process(metadata: Video.Processor.Packet) {
            output[metadata.time.timestamp.timeStamp] = metadata.originalTime
        }
        
        public func process(video: Video.Buffer) {
            let key = CMSampleBufferGetPresentationTimeStamp(video.sampleBuffer).value
            guard let originalTimeSeconds = output[key]?.timestamp.seconds
            else { assert(false); return }
            let currentTimeSeconds = CACurrentMediaTime();
            let delta = currentTimeSeconds - originalTimeSeconds
            
            output.removeValue(forKey: key)
            next.process(string: "\(delta)")
        }
    }
}
