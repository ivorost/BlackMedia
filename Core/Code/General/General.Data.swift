//
//  Processor.Data.swift
//  Capture
//
//  Created by Ivan Kh on 22.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation


public extension Data.Processor.Kind {
    static let other = Data.Processor.Kind(rawValue: "other")
    static let none = Data.Processor.Kind(rawValue: "none")
    static let capture = Data.Processor.Kind(rawValue: "capture")
    static let serializer = Data.Processor.Kind(rawValue: "serializer")
    static let deserializer = Data.Processor.Kind(rawValue: "deserializer")
    static let networkData = Data.Processor.Kind(rawValue: "networkData")
    static let networkDataOutput = Data.Processor.Kind(rawValue: "networkDataOutput")
    static let networkHelm = Data.Processor.Kind(rawValue: "networkHelm")
    static let networkHelmOutput = Data.Processor.Kind(rawValue: "networkHelmOutput")
}


public protocol DataProcessorProtocol : AnyObject {
    func process(data: Data)
}


public extension Data {
    final class Processor {
        static var shared: Proto = Base()
    }
}


public extension Data.Processor {
    typealias Proto = DataProcessorProtocol
}


public extension Data.Processor {
    class Base : Proto {
        
        private let prev: Proto?
        private let next: Proto?
        weak var nextWeak: Proto? = nil
        
        init(next: Proto? = nil) {
            self.prev = nil
            self.next = next
            self.nextWeak = next
        }
        
        init(prev: Proto, next: Proto? = nil) {
            self.prev = prev
            self.next = next
            self.nextWeak = next
        }
        
        public func process(data: Data) {
            prev?.process(data: data)
            nextWeak?.process(data: data)
        }
    }
}


extension Data.Processor {
    public struct Kind : Hashable, Equatable, RawRepresentable {
        public init(rawValue: String) { self.rawValue = rawValue }
        public let rawValue: String
    }
}


fileprivate extension Data.Processor {
    class Broadcast : Proto {
        private var array: [Proto?]
        
        init(_ array: [Proto?]) {
            self.array = array
        }
        
        func process(data: Data) {
            for i in array { i?.process(data: data) }
        }
    }
}


public func broadcast(_ x: [Data.Processor.Proto?]) -> Data.Processor.Proto? {
    broadcast(x, create: { Data.Processor.Broadcast($0) })
}


public extension Data.Processor {
    class Test : Session.Proto & Flushable.Proto {
        private let data: Data
        private let next: Proto
        
        public init(next: Proto, kbits: UInt) {
            let count = Int(kbits * 1024 / 8)
            var bytes = [UInt8](repeating: 0, count: count)
            
            for i in 0 ..< count {
                bytes[i] = UInt8.random(in: UInt8.min ... UInt8.max)
            }

            self.data = Data(bytes)
            self.next = next
        }
        
        public func start() throws {}
        public func stop() {}
        
        public func flush() {
            next.process(data: data)
        }
    }
}

