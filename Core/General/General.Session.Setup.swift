//
//  Session.Setup.swift
//  Capture
//
//  Created by Ivan Kh on 25.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AppKit


protocol SessionSetupProtocol : class {
    func session(_ session: Session.Proto, kind: Session.Kind)
    func complete() -> Session.Proto?
}


extension SessionSetupProtocol {
    func setup() -> Session.Proto? {
        session(Session.shared, kind: .initial)
        return complete()
    }
}


class SessionSetupBase : SessionSetupProtocol {
    func session(_ session: Session.Proto, kind: Session.Kind) {
    }
    
    func complete() -> Session.Proto? {
        return nil
    }
}


final class SessionSetup : SessionSetupBase {
    typealias Base = SessionSetupBase
    typealias Proto = SessionSetupProtocol
    static let shared = SessionSetup()
}


extension SessionSetup {
    class Slave : Base {
        private(set) weak var _root: Proto?
        
        init(root: Proto) {
            self._root = root
        }
        
        var root: Proto {
            return _root ?? SessionSetup.shared
        }
    }
}

extension SessionSetup {
    class Aggregator : Proto {
        private var sessions = [SessionProtocol]()
        
        func session(_ session: SessionProtocol, kind: Session.Kind) {
            assert(!sessions.contains {  $0 === session })
            sessions.append(session)
        }
        
        func complete() -> SessionProtocol? {
            return broadcast(sessions)
        }
    }
}


extension SessionSetup {
    class Chain : Proto {
        private let _next: Proto
        
        init(next: Proto) {
            self._next = next
        }
        
        var next: Proto {
            return _next
        }
        
        func session(_ session: Session.Proto, kind: Session.Kind) {
            next.session(session, kind: kind)
        }
        
        func complete() -> Session.Proto? {
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

extension SessionSetup {
    class DispatchSync : Chain {
        private let queue: DispatchQueue
        
        init(next: SessionSetup.Proto, queue: DispatchQueue) {
            self.queue = queue
            super.init(next: next)
        }
        
        override func complete() -> Session.Proto? {
            if let session = super.complete() {
                return Session.DispatchSync(session: session, queue: queue)
            }
            else {
                return nil
            }
        }
    }
}
