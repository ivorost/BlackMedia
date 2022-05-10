//
//  General.Flush.swift
//  Capture
//
//  Created by Ivan Kh on 08.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

public protocol FlushableProtocol : AnyObject {
    func flush()
}


public class Flushable : FlushableProtocol {
    static let shared = Flushable()
    public func flush() {}
}


public extension Flushable {
    typealias Proto = FlushableProtocol
}


public extension Flushable {
    class Proxy : Proto {
        var inner: Proto?
        
        public func flush() {
            inner?.flush()
        }
    }
}


public extension Flushable {
    class Vector : Proto {
        private let inner: [Proto]
        
        public init(_ vector: [Proto]) {
            self.inner = vector
        }
        
        public func flush() {
            inner.forEach { $0.flush() }
        }
    }
}


public extension Flushable {
    class Periodically : Proto, Session.Proto {
        private let next: Flushable.Proto
        private let interval: TimeInterval
        private var timer: Timer?
        
        public init(interval: TimeInterval, next: Flushable.Proto) {
            self.interval = interval
            self.next = next
        }
        
        public convenience init(next: Flushable.Proto) {
            self.init(interval: 0.33, next: next)
        }
        
        public func start() throws {
            timer = Timer.scheduledTimer(withTimeInterval: interval,
                                         repeats: true,
                                         block: { _ in self.flush() })
        }
        
        public func stop() {
            timer?.invalidate()
            timer = nil
        }
        
        public func flush() {
            next.flush()
        }
    }
}


public extension Flushable {
    class OperationsNumber : Proto {
        private let next: String.Processor.Proto
        private let queue: OperationQueue
        
        public init(queue: OperationQueue, next: String.Processor.Proto) {
            self.next = next
            self.queue = queue
        }
        
        public func flush() {
            next.process(string: "\(queue.operations.count)")
        }
    }
}
