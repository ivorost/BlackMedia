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


public extension Data {
    final class Processor: ProcessorToolbox<Data> {
        static var shared: AnyProto = Base()
    }
}


public extension Data {
    final class Producer: ProducerToolbox<Data> {}
}


public extension Data.Processor {
    class Base : Proto {
        
        private let prev: AnyProto?
        private let next: AnyProto?
        weak var nextWeak: AnyProto? = nil
        
        init(next: AnyProto? = nil) {
            self.prev = nil
            self.next = next
            self.nextWeak = next
        }
        
        init(prev: AnyProto, next: AnyProto? = nil) {
            self.prev = prev
            self.next = next
            self.nextWeak = next
        }
        
        public func process(_ data: Data) {
            prev?.process(data)
            nextWeak?.process(data)
        }
    }
}


extension Data.Processor {
    public struct Kind : Hashable, Equatable, RawRepresentable {
        public init(rawValue: String) { self.rawValue = rawValue }
        public let rawValue: String
    }
}


public extension Data.Processor {
    class Test : Session.Proto & Flushable.Proto {
        private let data: Data
        private let next: AnyProto
        
        public init(next: AnyProto, kbits: UInt) {
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
            next.process(data)
        }
    }
}

