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


public typealias FuncWithSession = (SessionProtocol) -> Void
public typealias FuncReturningSessionThrowing = () throws -> SessionProtocol


public protocol SessionProtocol : class {
    func start () throws
    func stop()
}


public class Session : SessionProtocol {
    public static let shared = Session()
    
    private let next: SessionProtocol?
    private let startFunc: FuncThrows
    private let stopFunc: Func
    
    public init() {
        next = nil
        startFunc = {}
        stopFunc = {}
    }
    
    public init(_ next: SessionProtocol?, start: @escaping FuncThrows = {}, stop: @escaping Func = {}) {
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


extension Session {
    public typealias Proto = SessionProtocol
    public typealias Setup = SessionSetupProtocol

    public struct Kind : Hashable, Equatable, RawRepresentable {
        public init(rawValue: String) { self.rawValue = rawValue }
        public let rawValue: String
    }
}


extension Session {
    class Broadcast : SessionProtocol {
        
        private var x: [SessionProtocol?]
        
        init(_ x: [SessionProtocol?]) {
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
    class DispatchSync : SessionProtocol {
        
        let session: SessionProtocol
        let queue: DispatchQueue
        
        public init(session: SessionProtocol, queue: DispatchQueue) {
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


public func broadcast(_ x: [SessionProtocol?]) -> SessionProtocol? {
    broadcast(x, create: { Session.Broadcast($0) })
}
