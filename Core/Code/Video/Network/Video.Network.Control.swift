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
        let server: Data.Processor.Proto
        
        init(server: Data.Processor.Proto, next: Video.Processor.Proto? = nil) {
            self.server = server
            super.init(next: next)
        }
        
        override func process(video: Video.Buffer) {
            let sampleTime = video.sampleBuffer.presentationSeconds
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
}


public extension Video.Processor {
    class SenderQuality : Base, Data.Processor.Proto {
        
        private var slowing = false
        private var lastFrameSent: Date?
        
        public override func process(video: Video.Buffer) {
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
        
        public func process(data: Data) {
            let message = String(data: data, encoding: .utf8)
            
            if message == "easy" {
                slowing = true
            }
            else if message == "hard" {
                slowing = false
            }
        }
    }
}


public extension Video.Processor {
    class SenderQualityDuplicates : Base {
        private let next: Video.Processor.Proto
        private var sequenceCount = 0
        private let lock = NSLock()
        
        init(next: Video.Processor.Proto) {
            self.next = next
            super.init()
        }
        
        public override func process(video: Video.Buffer) {
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
                next.process(video: video)
            }
        }
    }
}


extension Video.Setup {
    public class SenderQuality : Slave {
        private var networkSenderListener: Data.Processor.Base?
        private var control: Video.Processor.Proto?
        
        public override func video(_ video: Video.Processor.Proto, kind: Video.Processor.Kind) -> Video.Processor.Proto {
            var result = video
            
            if kind == .capture {
                assert(networkSenderListener != nil)
                
                let control = create(next: result)
                self.control = control
                networkSenderListener?.nextWeak = control
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
        
        public override func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
            var result = data
            
            if kind == .networkHelmOutput {
                let networkSenderListener = Data.Processor.Base(prev: result)
                
                self.networkSenderListener = networkSenderListener
                result = networkSenderListener
            }
            
            return super.data(result, kind: kind)
        }
        
        func create(next: Video.Processor.Proto) -> Video.Processor.Proto & Data.Processor.Proto {
            return Video.Processor.SenderQuality(next: next)
        }
    }
}


extension Video.Setup {
    public class ViewerQuality : Slave {
        private let server = Data.Processor.Base()
        
        public override func video(_ video: Video.Processor.Proto, kind: Video.Processor.Kind) -> Video.Processor.Proto {
            var result = video
            
            if kind == .deserializer {
                result = Video.Processor.ViewerQuality(server: server, next: result)
            }
            
            return super.video(result, kind: kind)
        }
        
        public override func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
            if kind == .networkData {
                server.nextWeak = data
            }
            
            return super.data(data, kind: kind)
        }
    }
}
