//
//  General.Flush.swift
//  Capture
//
//  Created by Ivan Kh on 08.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

protocol FlushableProtocol : class {
    func flush()
}


class Flushable : FlushableProtocol {
    static let shared = Flushable()
    func flush() {}
}


extension Flushable {
    typealias Proto = FlushableProtocol
}


extension Flushable {
    class Vector : Proto {
        private let inner: [Proto]
        
        init(_ vector: [Proto]) {
            self.inner = vector
        }
        
        func flush() {
            inner.forEach { $0.flush() }
        }
    }
}


extension Flushable {
    class Periodically : Proto, SessionProtocol {
        private let next: Flushable.Proto
        private let interval: TimeInterval
        private var timer: Timer?
        
        init(interval: TimeInterval, next: Flushable.Proto) {
            self.interval = interval
            self.next = next
        }
        
        convenience init(next: Flushable.Proto) {
            self.init(interval: 0.33, next: next)
        }
        
        func start() throws {
            timer = Timer.scheduledTimer(withTimeInterval: interval,
                                         repeats: true,
                                         block: { _ in self.flush() })
        }
        
        func stop() {
            timer?.invalidate()
            timer = nil
        }
        
        func flush() {
            next.flush()
        }
    }
}
