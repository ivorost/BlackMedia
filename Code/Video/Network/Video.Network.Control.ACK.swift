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
        fileprivate var server: Data.Processor.AnyProto?
        
        init(server: Data.Processor.AnyProto?) {
            self.server = server
            super.init(metadataOnly: true)
        }
        
        public override func process(metadata: Video.Processor.Packet) {
            server?.process("ack \(metadata.ID)".data(using: .utf8)!)
        }
    }
}


public extension Video.Processor {
    class SenderACKCapture : Base, Flushable.Proto {
        private(set) var data: Data.Processor.AnyProto = Data.Processor.shared
        private var queue = [(ID: UInt, timestamp: Date)]()
        private var metric: String.Processor.AnyProto
        private let lock = NSRecursiveLock()
        private var lastVideoBuffer: Video.Sample?
        private var processTimeStamp: Date?
        private let timebase: Capture.Timebase

        init(next: Video.Processor.AnyProto, timebase: Capture.Timebase, metric: String.Processor.AnyProto) {
            self.timebase = timebase
            self.metric = metric
            super.init(next: next)
            self.data = Data.Processor.Callback { [weak self] data in
                self?.process(data)
            }
        }
        
        public override func process(_ video: Video.Sample) {
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
                super.process(video)
            }
        }
        
        public func process(_ data: Data) {
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
                process(lastVideoBuffer)
                
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
            
            metric.process("\(time) \(string)")
        }
    }
}


public extension Video.Setup {
    class ViewerACK : Slave {
        private var server: Data.Processor.AnyProto?
        private var ack: Data.Processor.VideoViewerACK?
        
        public override func data(_ data: Data.Processor.AnyProto, kind: Data.Processor.Kind) -> Data.Processor.AnyProto {
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
        private let timebase: BlackMedia.Capture.Timebase
        private let metric: String.Processor.AnyProto
        
        public init(root: Video.Setup.Proto,
                    timebase: BlackMedia.Capture.Timebase,
                    metric: String.Processor.AnyProto = String.Processor.shared) {
            self.timebase = timebase
            self.metric = metric
            super.init(root: root)
        }

        override func create(next: any ProcessorProtocol<Video.Sample>,
                             data: inout Data.Processor.AnyProto) -> any ProcessorProtocol<Video.Sample> {
            let result = Video.Processor.SenderACKCapture(next: next, timebase: timebase, metric: metric)
            data = result.data
            return result
        }
    }
}
