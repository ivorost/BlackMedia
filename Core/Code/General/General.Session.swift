//
//  AV.Session.swift
//  Capture
//
//  Created by Ivan Kh on 25.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation


public extension Session.Kind {
    static let other = Session.Kind(rawValue: "other")
    static let initial = Session.Kind(rawValue: "initial")
    static let input = Session.Kind(rawValue: "input")
    static let capture = Session.Kind(rawValue: "capture")
    static let networkData = Session.Kind(rawValue: "networkData")
    static let networkHelm = Session.Kind(rawValue: "networkHelm")
}


public typealias FuncWithSession = (Session.Proto) -> Void
public typealias FuncReturningSessionThrowing = () throws -> Session.Proto


public protocol SessionProtocol : AnyObject {
    func start () throws
    func stop()
}


extension Session {
    public typealias Proto = SessionProtocol
}


public final class Session {
    public static let shared: Proto = Base()
}


extension Session {
    public class Base : Proto {
        
        private let next: Proto?
        private let startFunc: FuncThrows
        private let stopFunc: Func
        
        public init() {
            next = nil
            startFunc = {}
            stopFunc = {}
        }
        
        public init(_ next: Proto?, start: @escaping FuncThrows = {}, stop: @escaping Func = {}) {
            self.next = next
            self.startFunc = start
            self.stopFunc = stop
        }
        
        public func start() throws {
            try startFunc()
            try next?.start()
        }
        
        public func stop() {
            stopFunc()
            next?.stop()
        }
    }
}


extension Session {
    public struct Kind : Hashable, Equatable, RawRepresentable {
        public init(rawValue: String) { self.rawValue = rawValue }
        public let rawValue: String
    }
}


extension Session {
    class Broadcast : Proto {
        
        private var x: [Proto?]
        
        init(_ x: [Proto?]) {
            self.x = x
        }
        
        func start () throws {
            try x.forEach { try $0?.start() }
        }
        
        func stop() {
            x.reversed().forEach {
                $0?.stop()
            }
        }
    }
}


public extension Session {
    class DispatchSync : Proto {
        
        let session: Proto
        let queue: DispatchQueue
        
        public init(session: Proto, queue: DispatchQueue) {
            self.session = session
            self.queue = queue
        }
        
        public func start () throws {
            try queue.sync {
                try session.start()
            }
        }
        
        public func stop() {
            queue.syncSafe {
                session.stop()
            }
        }
    }
}


public extension Session {
    class Background : Proto {
        private let session: Proto
        private let thread: BackgroundThread
        
        public init(session: Proto, thread: BackgroundThread) {
            self.session = session
            self.thread = thread
        }
        
        public func start () throws {
            thread.start()

            try thread.sync {
                try self.session.start()
            }
        }
        
        public func stop() {
            thread.sync {
                self.session.stop()
            }
            
            thread.cancel()
        }
    }
}


public func broadcast(_ x: [Session.Proto?]) -> Session.Proto? {
    broadcast(x, create: { Session.Broadcast($0) })
}
