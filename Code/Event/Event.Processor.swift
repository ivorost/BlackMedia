//
//  Processor.Event.swift
//  Capture
//
//  Created by Ivan Kh on 23.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

#if canImport(AppKit)
import AppKit
#endif



#if canImport(AppKit)
public final class EventProcessor : ProcessorToolbox<NSEvent> {
    static let shared = Base()
}
#endif


#if canImport(AppKit)
public extension EventProcessor {
    struct Kind : Hashable, Equatable, RawRepresentable {
        public init(rawValue: String) { self.rawValue = rawValue }
        public let rawValue: String
    }
}
#endif


#if canImport(AppKit)
public extension EventProcessor {
    class Chain : Proto {
        private let prev: AnyProto?
        private let next: AnyProto?

        init(next: AnyProto) {
            self.prev = nil
            self.next = next
        }
        
        init(prev: AnyProto, next: AnyProto) {
            self.prev = prev
            self.next = next
        }
        
        public func process(_ event: NSEvent) {
            self.prev?.process(event)
            self.next?.process(event)
        }
    }
}
#endif


#if canImport(AppKit)
public extension EventProcessor {
    class DispatchAsync : Chain {
        private let queue: DispatchQueue
        
        public init(next: AnyProto, queue: DispatchQueue) {
            self.queue = queue
            super.init(next: next)
        }
        
        public override func process(_ event: NSEvent) {
            queue.async {
                super.process(event)
            }
        }
    }
}
#endif
