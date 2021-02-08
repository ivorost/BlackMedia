//
//  Session.Setup.swift
//  Capture
//
//  Created by Ivan Kh on 25.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation


public protocol SessionSetupProtocol : class {
    func session(_ session: Session.Proto, kind: Session.Kind)
    func complete() -> Session.Proto?
}


public extension SessionSetupProtocol {
    func setup() -> Session.Proto? {
        session(Session.shared, kind: .initial)
        return complete()
    }
}


public class SessionSetupBase : SessionSetupProtocol {
    public func session(_ session: Session.Proto, kind: Session.Kind) {
    }
    
    public func complete() -> Session.Proto? {
        return nil
    }
}


public final class SessionSetup : SessionSetupBase {
    public typealias Base = SessionSetupBase
    public typealias Proto = SessionSetupProtocol
    public static let shared = SessionSetup()
}


public extension SessionSetup {
    class Slave : Base {
        private(set) weak var _root: Proto?
        
        public init(root: Proto) {
            self._root = root
        }
        
        var root: Proto {
            return _root ?? SessionSetup.shared
        }
    }
}

public extension SessionSetup {
    class Aggregator : Proto {
        private var sessions = [SessionProtocol]()
        
        public init() {}
        
        public func session(_ session: SessionProtocol, kind: Session.Kind) {
            assert(!sessions.contains {  $0 === session })
            sessions.append(session)
        }
        
        public func complete() -> SessionProtocol? {
            return broadcast(sessions)
        }
    }
}


public extension SessionSetup {
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
    
extension SessionSetup {
    class Vector : ProcessorWithVector<Proto>, Proto {
        func session(_ session: SessionProtocol, kind: Session.Kind) {
            vector.forEach { $0.session(session, kind: kind) }
        }

        func complete() -> SessionProtocol? {
            return broadcast(vector.map { $0.complete() })
        }
    }
}

public extension SessionSetup {
    class DispatchSync : Chain {
        private let queue: DispatchQueue
        
        public init(next: SessionSetup.Proto, queue: DispatchQueue) {
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
