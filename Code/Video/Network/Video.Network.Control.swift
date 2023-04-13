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


extension Video.Processor {
    class ViewerQuality : Base {
        var bestSample: Double?
        var localTime: Date?
        var slowing = false
        let server: Data.Processor.AnyProto
        
        init(server: Data.Processor.AnyProto, next: Video.Processor.AnyProto? = nil) {
            self.server = server
            super.init(next: next)
        }
        
        override func process(_ video: Video.Sample) {
            let sampleTime = video.sampleBuffer.presentationSeconds
            var gap = 0.0
            
            super.process(video)

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
                server.process("easy".data(using: .utf8)!)
            }
            
            if gap < .maxGap && slowing == true {
                slowing = false
                server.process("hard".data(using: .utf8)!)
            }

            super.process(video)
        }
    }
}


public extension Video.Processor {
    class SenderQuality : Base {
        class DataProcessor: Data.Processor.Proto {
            private(set) var slowing = false

            public func process(_ data: Data) {
                let message = String(data: data, encoding: .utf8)

                if message == "easy" {
                    slowing = true
                }
                else if message == "hard" {
                    slowing = false
                }
            }
        }

        let data = DataProcessor()
        private var lastFrameSent: Date?
        
        public override func process(_ video: Video.Sample) {
            if data.slowing {
                if let lastFrameSent = lastFrameSent, Date().timeIntervalSince(lastFrameSent) > 1.0 {
                    super.process(video)
                    self.lastFrameSent = Date()
                }
                
                if lastFrameSent == nil {
                    lastFrameSent = Date()
                }
            }
            else {
                super.process(video)
            }
        }
        
    }
}


public extension Video.Processor {
    class SenderQualityDuplicates : Base {
        private let next: Video.Processor.AnyProto
        private var sequenceCount = 0
        private let lock = NSLock()
        
        init(next: Video.Processor.AnyProto) {
            self.next = next
            super.init()
        }
        
        public override func process(_ video: Video.Sample) {
            var process = false
            
            lock.locked {
                sequenceCount += 1
                
                if video.flags.contains(.duplicate), sequenceCount == 1 {
                    process = true
                }
                
                if !video.flags.contains(.duplicate) {
                    sequenceCount = 0
                }
            }
            
            if process {
                next.process(video)
            }
        }
    }
}


extension Video.Setup {
    public class SenderQuality : Slave {
        private var networkSenderListener: Data.Processor.Base?
        private var control: Video.Processor.AnyProto?
        
        public override func video(_ video: Video.Processor.AnyProto, kind: Video.Processor.Kind) -> Video.Processor.AnyProto {
            var result = video
            
            if kind == .capture {
                assert(networkSenderListener != nil)

                var controlData: Data.Processor.AnyProto = Data.Processor.shared
                let control = create(next: result, data: &controlData)
                self.control = control
                networkSenderListener?.nextWeak = controlData
                result = control
            }
            
            if kind == .duplicatesNext {
                if let control = control {
                    let encoderDuplicates = Video.Processor.SenderQualityDuplicates(next: control)
                    result = Video.Processor.Base(prev: result, next: encoderDuplicates)
                }
                else {
                    assert(false)
                }
            }
            
            return super.video(result, kind: kind)
        }
        
        public override func data(_ data: Data.Processor.AnyProto, kind: Data.Processor.Kind) -> Data.Processor.AnyProto {
            var result = data
            
            if kind == .networkHelmOutput {
                let networkSenderListener = Data.Processor.Base(prev: result)
                
                self.networkSenderListener = networkSenderListener
                result = networkSenderListener
            }
            
            return super.data(result, kind: kind)
        }
        
        func create(next: any ProcessorProtocol<Video.Sample>,
                    data: inout Data.Processor.AnyProto) -> any ProcessorProtocol<Video.Sample> {
            let result = Video.Processor.SenderQuality(next: next)
            data = result.data
            return result
        }
    }
}


extension Video.Setup {
    public class ViewerQuality : Slave {
        private let server = Data.Processor.Base()
        
        public override func video(_ video: Video.Processor.AnyProto, kind: Video.Processor.Kind) -> Video.Processor.AnyProto {
            var result = video
            
            if kind == .deserializer {
                result = Video.Processor.ViewerQuality(server: server, next: result)
            }
            
            return super.video(result, kind: kind)
        }
        
        public override func data(_ data: Data.Processor.AnyProto, kind: Data.Processor.Kind) -> Data.Processor.AnyProto {
            if kind == .networkData {
                server.nextWeak = data
            }
            
            return super.data(data, kind: kind)
        }
    }
}
