//
//  Video.Utils.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 30.04.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation

public final class Capture {}


public protocol CaptureProtocol : Session.Proto & Data.Processor.Proto {
}


public extension Capture {
    typealias Proto = CaptureProtocol
}


public extension Capture {
    enum Error : Swift.Error {
        case audio(_ inner: Swift.Error)
        case video(_ inner: Swift.Error)
    }
}


public extension Capture {
    static let queue = DispatchQueue.CreateCheckable("capture_queue")
    static let shared: Proto = Base()
}


public extension Capture {
    class Base : Capture.Proto {
        public func start() throws {}
        public func stop() {}
        public func process(data: Data) {}
    }
}


public extension Capture {
    class Timebase : Session.Base {
        private(set) var date: Date = Date()
        
        public override func start() throws {
            date = Date()
        }
    }
}


public extension Session.Kind {
    static let avCapture = Session.Kind(rawValue: "avCapture")
    static let encoder = Session.Kind(rawValue: "encoder")
}
