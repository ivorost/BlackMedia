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
    final class Processor: ProcessorToolbox<Video.Sample> {
        public static let shared: AnyProto = Base()
    }
}


public extension Video {
    final class Producer: ProducerToolbox<Video.Sample> {}
}


public extension Video.Processor {
    class Base : Proto {
        
        private let next: AnyProto?
        private let prev: AnyProto?
        private let measure: MeasureProtocol?
        
        init(next: AnyProto? = nil, measure: MeasureProtocol? = nil) {
            self.prev = nil
            self.next = next
            self.measure = measure
        }
        
        init(prev: AnyProto, measure: MeasureProtocol? = nil) {
            self.prev = prev
            self.next = nil
            self.measure = measure
        }
        
        init(prev: AnyProto, next: AnyProto? = nil) {
            self.prev = prev
            self.next = next
            self.measure = nil
        }
        
        public func process(_ video: Video.Sample) {
            prev?.process(video)
            measure?.begin()
            let processNext = processSelf(video: video)
            measure?.end()
            if processNext { next?.process(video) }
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
    class Dispatch : ProcessorProtocol {
        let next: AnyProto?
        let queue: OperationQueue
        
        init(next: AnyProto?, queue: OperationQueue) {
            self.next = next
            self.queue = queue
        }
        
        public func process(_ video: Video.Sample) {
            if let next = next {
                queue.addOperation {
                    next.process(video)
                }
            }
        }
    }
}
