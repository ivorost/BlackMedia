//
//  Processor.Event.swift
//  Capture
//
//  Created by Ivan Kh on 23.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AppKit


protocol EventProcessorProtocol {
    func process(event: NSEvent)
}


class EventProcessorBase : EventProcessorProtocol {
    func process(event: NSEvent) {
    }
}


class EventProcessor : EventProcessorBase {
    static let shared = EventProcessor()
}


extension EventProcessor {
    public struct Kind : Hashable, Equatable, RawRepresentable {
        let rawValue: String
    }
}


extension EventProcessor {
    typealias Base = EventProcessorBase
    typealias Proto = EventProcessorProtocol
}


extension EventProcessor {
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
        
        func process(event: NSEvent) {
            self.prev?.process(event: event)
            self.next?.process(event: event)
        }
    }
}


extension EventProcessor {
    class DispatchAsync : Chain {
        private let queue: DispatchQueue
        
        init(next: EventProcessor.Proto, queue: DispatchQueue) {
            self.queue = queue
            super.init(next: next)
        }
        
        override func process(event: NSEvent) {
            queue.async {
                super.process(event: event)
            }
        }
    }
}
