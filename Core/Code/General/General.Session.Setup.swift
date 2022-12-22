//
//  Session.Setup.swift
//  Capture
//
//  Created by Ivan Kh on 25.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation


public extension Session {
    final class Setup {
        public static let shared: Proto = Base()
    }
}


public protocol SessionSetupProtocol : AnyObject {
    func session(_ session: Session.Proto, kind: Session.Kind)
    func complete() -> Session.Proto?
}


public extension Session.Setup {
    typealias Proto = SessionSetupProtocol
}


public extension Session.Setup.Proto {
    func setup() -> Session.Proto? {
        session(Session.shared, kind: .initial)
        return complete()
    }
}


extension Session.Setup {
    open class Base : Proto {
        open func session(_ session: Session.Proto, kind: Session.Kind) {
        }
        
        open func complete() -> Session.Proto? {
            return nil
        }
    }
}


extension Session.Setup {
    open class Slave : Base {
        public private(set) weak var _root: Proto?
        
        public init(root: Proto) {
            self._root = root
        }
        
        var root: Proto {
            return _root ?? shared
        }
    }
}

public extension Session.Setup {
    class Aggregator : Proto {
        private var sessions = [Session.Proto]()
        
        public init() {}
        
        public func session(_ session: Session.Proto, kind: Session.Kind) {
            assert(!sessions.contains {  $0 === session })
            sessions.append(session)
        }
        
        public func complete() -> Session.Proto? {
            return broadcast(sessions)
        }
    }
}


public extension Session.Setup {
    class Chain : Proto {
        private let _next: Proto
        
        init(next: Proto) {
            self._next = next
        }
        
        var next: Proto {
            return _next
        }
        
        public func session(_ session: Session.Proto, kind: Session.Kind) {
            next.session(session, kind: kind)
        }
        
        public func complete() -> Session.Proto? {
            return next.complete()
        }
    }
}


extension Session.Setup {
    open class Static : Slave {
        private let session: Session.Proto
        
        public init(root: Proto, session: Session.Proto) {
            self.session = session
            super.init(root: root)
        }
        
        public override func session(_ session: Session.Proto, kind: Session.Kind) {
            if kind == .initial {
                root.session(self.session, kind: .other)
            }
        }
    }
}


public extension Session.Setup {
    class Vector : ProcessorWithVector<Proto>, Proto {
        public func session(_ session: Session.Proto, kind: Session.Kind) {
            vector.forEach { $0.session(session, kind: kind) }
        }

        public func complete() -> Session.Proto? {
            return broadcast(vector.map { $0.complete() })
        }
    }
}


public extension Session.Setup {
    class DispatchSync : Chain {
        private let queue: DispatchQueue
        
        public init(next: Session.Setup.Proto, queue: DispatchQueue) {
            self.queue = queue
            super.init(next: next)
        }
        
        public override func complete() -> Session.Proto? {
            if let session = super.complete() {
                return Session.DispatchSync(session: session, queue: queue)
            }
            else {
                return nil
            }
        }
    }
}


public extension Session.Setup {
    class Background : Chain {
        private let thread: BackgroundThread

        public init(next: Session.Setup.Proto, thread: BackgroundThread) {
            self.thread = thread
            super.init(next: next)
        }
        
        public override func complete() -> Session.Proto? {
            if let session = super.complete() {
                return Session.Background(session: session, thread: thread)
            }
            else {
                return nil
            }
        }
    }
}
