//
//  Video.Processor.swift
//  Core
//
//  Created by Ivan Kh on 27.01.2022.
//

import Foundation

public protocol VideoProcessorProtocol {
    func process(video: Video.Sample)
}


public extension Video {
    final class Processor {
        static let shared: Proto = Base()
    }
}


public extension Video.Processor {
    typealias Proto = VideoProcessorProtocol
}


public extension Video.Processor {
    class Base : Proto {
        
        private let next: Proto?
        private let prev: Proto?
        private let measure: MeasureProtocol?
        
        init(next: Proto? = nil, measure: MeasureProtocol? = nil) {
            self.prev = nil
            self.next = next
            self.measure = measure
        }
        
        init(prev: Proto, measure: MeasureProtocol? = nil) {
            self.prev = prev
            self.next = nil
            self.measure = measure
        }
        
        init(prev: Proto, next: Proto? = nil) {
            self.prev = prev
            self.next = next
            self.measure = nil
        }
        
        public func process(video: Video.Sample) {
            prev?.process(video: video)
            measure?.begin()
            let processNext = processSelf(video: video)
            measure?.end()
            if processNext { next?.process(video: video) }
        }
        
        func processSelf(video: Video.Sample) -> Bool {
            // to override
            return true
        }
    }
}


public extension Video.Processor {
    struct Kind : Hashable, Equatable, RawRepresentable {
        public init(rawValue: String) { self.rawValue = rawValue }
        public let rawValue: String
    }
}



public extension Video.Processor {
    class Dispatch : Proto {
        let next: Proto?
        let queue: OperationQueue
        
        init(next: Proto?, queue: OperationQueue) {
            self.next = next
            self.queue = queue
        }
        
        public func process(video: Video.Sample) {
            if let next = next {
                queue.addOperation {
                    next.process(video: video)
                }
            }
        }
    }
}


public extension Video.Processor {
    class Broadcast : Proto {
        private let array: [Proto?]
        
        init(_ array: [Proto?]) {
            self.array = array
        }
        
        public func process(video: Video.Sample) {
            for i in array { i?.process(video: video) }
        }
    }
}


public func broadcast(_ x: [Video.Processor.Proto]) -> Video.Processor.Proto? {
    return broadcast(x, create: { Video.Processor.Broadcast($0) })
}

