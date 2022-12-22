//
//  Network.ACK.swift
//  Capture
//
//  Created by Ivan Kh on 17.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//


import AVFoundation


public extension Data.Processor {
    class VideoViewerACK : DeserializerH264Base {
        fileprivate var server: Data.Processor.Proto?
        
        init(server: Data.Processor.Proto?) {
            self.server = server
            super.init(metadataOnly: true)
        }
        
        public override func process(metadata: Video.Processor.Packet) {
            server?.process(data: "ack \(metadata.ID)".data(using: .utf8)!)
        }
    }
}


public extension Video.Processor {
    class SenderACKCapture : Base, Data.Processor.Proto, Flushable.Proto {
        
        private var queue = [(ID: UInt, timestamp: Date)]()
        private var metric: String.Processor.Proto
        private let lock = NSRecursiveLock()
        private var lastVideoBuffer: Video.Sample?
        private var processTimeStamp: Date?
        private let timebase: Capture.Timebase
        
        init(next: Video.Processor.Proto, timebase: Capture.Timebase, metric: String.Processor.Proto) {
            self.timebase = timebase
            self.metric = metric
            super.init(next: next)
        }
        
        public override func process(video: Video.Sample) {
            var process = false
            
            lock.locked {
                flushState()
                
#if os(OSX)
                let capacity = 2
#else
                let capacity = 1
#endif
                
                if queue.count < capacity {
                    process = true
                    queue.append((ID: video.ID, timestamp: Date()))
                    self.processTimeStamp = Date()
                }
            }
            
            if process {
                super.process(video: video)
            }
        }
        
        public func process(data: Data) {
            guard let string = String(data: data, encoding: .utf8), string.hasPrefix("ack ") else { return }
            let idString = string.suffix(from: string.index(string.startIndex, offsetBy: 4))
            
            if let ID = UInt(idString) {
                lock.locked {
                    if let removed = queue.removeFirst(where: { $0.ID == ID }) {
                        metric(ID: removed.ID, timestamp: queue.last?.timestamp ?? removed.timestamp)
                    }
                    
                    flush()
                }
            }
            else {
                assert(false)
            }
        }
        
        private func flushState() {
            lock.locked {
                var flush = false
                
                if !flush, processTimeStamp == nil {
                    flush = true
                }
                
                if !flush, let timestamp = processTimeStamp, Date().timeIntervalSince(timestamp) > 3 {
                    flush = true
                }
                
                if flush && queue.count > 0 {
                    let removed = queue.removeFirst()
                    metric(ID: removed.ID, timestamp: queue.last?.timestamp ?? removed.timestamp, comment: "(timeout)")
                }
            }
        }
        
        public func flush() {
            var lastVideoBuffer: Video.Sample?
            
            lock.locked {
                lastVideoBuffer = self.lastVideoBuffer
                self.lastVideoBuffer = nil
            }
            
            if let lastVideoBuffer = lastVideoBuffer {
                process(video: lastVideoBuffer)
                
            }
        }
        
        private func metric(ID: UInt, timestamp: Date, comment: String = "") {
            let idString = "ID \(ID)".padding(toLength: 9, withPad: " ", startingAt: 0)
            let timeString = String(format: "duration %.2f", Date().timeIntervalSince(timestamp))
            metric("\(idString) \(timeString) \(comment)")
        }
        
        private func metric(_ string: String) {
            let time = String(format: "[%.2f]", Date().timeIntervalSince(timebase.date))
                .padding(toLength: 9, withPad: " ", startingAt: 0)
            
            metric.process(string: "\(time) \(string)")
        }
    }
}


public extension Video.Setup {
    class ViewerACK : Slave {
        private var server: Data.Processor.Proto?
        private var ack: Data.Processor.VideoViewerACK?
        
        public override func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
            var result = data
            
            if kind == .networkHelm {
                server = data
                ack?.server = server
            }
            
            if kind == .networkDataOutput {
                let ack = Data.Processor.VideoViewerACK(server: server)
                self.ack = ack
                result = Data.Processor.Base(prev: result, next: ack)
            }
            
            return super.data(result, kind: kind)
        }
    }
}


public extension Video.Setup {
    class SenderACK : Video.Setup.SenderQuality {
        private let timebase: Core.Capture.Timebase
        private let metric: String.Processor.Proto
        
        public init(root: Video.Setup.Proto,
                    timebase: Core.Capture.Timebase,
                    metric: String.Processor.Proto = String.Processor.shared) {
            self.timebase = timebase
            self.metric = metric
            super.init(root: root)
        }
        
        override func create(next: Video.Processor.Proto) -> Video.Processor.Proto & Data.Processor.Proto {
            return Video.Processor.SenderACKCapture(next: next, timebase: timebase, metric: metric)
        }
    }
}
