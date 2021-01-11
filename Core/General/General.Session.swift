//
//  AV.Session.swift
//  Capture
//
//  Created by Ivan Kh on 25.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation


extension Session.Kind {
    static let other = Session.Kind(rawValue: "other")
    static let initial = Session.Kind(rawValue: "initial")
    static let input = Session.Kind(rawValue: "input")
    static let capture = Session.Kind(rawValue: "capture")
    static let networkData = Session.Kind(rawValue: "networkData")
    static let networkHelm = Session.Kind(rawValue: "networkHelm")
}


typealias FuncWithSession = (SessionProtocol) -> Void
typealias FuncReturningSessionThrowing = () throws -> SessionProtocol


protocol SessionProtocol : class {
    func start () throws
    func stop()
}


class Session : SessionProtocol {
    static let shared = Session()
    
    private let next: SessionProtocol?
    private let startFunc: FuncThrows
    private let stopFunc: Func
    
    init() {
        next = nil
        startFunc = {}
        stopFunc = {}
    }
    
    init(_ next: SessionProtocol?, start: @escaping FuncThrows = {}, stop: @escaping Func = {}) {
        self.next = next
        self.startFunc = start
        self.stopFunc = stop
    }

    func start() throws {
        try startFunc()
        try next?.start()
    }

    func stop() {
        stopFunc()
        next?.stop()
    }
}


extension Session {
    typealias Proto = SessionProtocol
    typealias Setup = SessionSetupProtocol

    public struct Kind : Hashable, Equatable, RawRepresentable {
        let rawValue: String
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

extension Session {
    class DispatchSync : SessionProtocol {
        
        let session: SessionProtocol
        let queue: DispatchQueue
        
        init(session: SessionProtocol, queue: DispatchQueue) {
            self.session = session
            self.queue = queue
        }
        
        func start () throws {
            try queue.sync {
                try session.start()
            }
        }
        
        func stop() {
            queue.sync {
                session.stop()
            }
        }
    }
}

func broadcast(_ x: [SessionProtocol?]) -> SessionProtocol? {
    broadcast(x, create: { Session.Broadcast($0) })
}
