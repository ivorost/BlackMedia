//
//  Video.FPS.swift
//  Capture
//
//  Created by Ivan Kh on 01.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation


extension Video {
    class Measure : ProcessorProtocol {
        private let measure: MeasureProtocol
        private let next: Processor.AnyProto
        
        init(measure: MeasureProtocol, next: Processor.AnyProto) {
            self.measure = measure
            self.next = next
        }
        
        func process(_ video: Sample) {
            measure.begin()
            next.process(video)
            measure.end()
        }
    }
}


public extension Video.Processor {
    class OutputPresentationTime : ProcessorProtocol {
        private let string: String.Processor.AnyProto
        private let timebase: Capture.Timebase
        private var startTime: Double?
        private let lock = NSLock()
        
        public init(string: String.Processor.AnyProto, timebase: Capture.Timebase) {
            self.string = string
            self.timebase = timebase
        }
        
        public func process(_ video: Video.Sample) {
            lock.locked {
                if startTime == nil {
                    startTime = video.sampleBuffer.presentationSeconds
                }
                
                if let startTime = startTime {
                    let clock = "\(Date().timeIntervalSince(timebase.date))"
                        .padding(toLength: 10, withPad: " ", startingAt: 0)
                    let presentation = "\(video.sampleBuffer.presentationSeconds - startTime)"
                    
                    string.process("\(clock) : \(presentation)")
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
        
        public override func video(_ video: Video.Processor.AnyProto, kind: Video.Processor.Kind) -> Video.Processor.AnyProto {
            var result = video
            
            if kind == self.kind {
                result = Video.Processor.Base(prev: result, measure: measure)
            }
            
            return result
        }
    }
}


public extension Video.Processor {
    class PresentationDelay : Data.Processor.DeserializerH264Base {
        private(set) var video: AnyProto = Video.Processor.shared
        private let next: String.Processor.AnyProto
        private var output = [Int64 : Video.Time]()

        public init(next: String.Processor.AnyProto) {
            self.next = next
            super.init(metadataOnly: true)
            video = Callback { [weak self] video in
                self?.process(video)
            }
        }
        
        public override func process(metadata: Video.Processor.Packet) {
            output[metadata.time.timestamp.timeStamp] = metadata.originalTime
        }
        
        public func process(_ video: Video.Sample) {
            let key = CMSampleBufferGetPresentationTimeStamp(video.sampleBuffer).value
            guard let originalTimeSeconds = output[key]?.timestamp.seconds
            else { assert(false); return }
            let currentTimeSeconds = CACurrentMediaTime();
            let delta = currentTimeSeconds - originalTimeSeconds
            
            output.removeValue(forKey: key)
            next.process("\(delta)")
        }
    }
}
