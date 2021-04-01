//
//  Processor.Event.swift
//  Capture
//
//  Created by Ivan Kh on 23.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AppKit


public protocol EventProcessorProtocol {
    func process(event: NSEvent)
}


public class EventProcessorBase : EventProcessorProtocol {
    public func process(event: NSEvent) {
    }
}


public class EventProcessor : EventProcessorBase {
    static let shared = EventProcessor()
}


public extension EventProcessor {
    struct Kind : Hashable, Equatable, RawRepresentable {
        public init(rawValue: String) { self.rawValue = rawValue }
        public let rawValue: String
    }
}


public extension EventProcessor {
    typealias Base = EventProcessorBase
    typealias Proto = EventProcessorProtocol
}


public extension EventProcessor {
    class Chain : Proto {
        private let prev: Proto?
        private let next: Proto?

        init(next: Proto) {
            self.prev = nil
            self.next = next
        }
        
        init(prev: Proto, next: Proto) {
            self.prev = prev
            self.next = next
        }
        
        public func process(event: NSEvent) {
            self.prev?.process(event: event)
            self.next?.process(event: event)
        }
    }
}


public extension EventProcessor {
    class DispatchAsync : Chain {
        private let queue: DispatchQueue
        
        public init(next: EventProcessor.Proto, queue: DispatchQueue) {
            self.queue = queue
            super.init(next: next)
        }
        
        public override func process(event: NSEvent) {
            queue.async {
                super.process(event: event)
            }
        }
    }
}
