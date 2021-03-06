//
//  Processor.Data.swift
//  Capture
//
//  Created by Ivan Kh on 22.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation


public extension DataProcessor.Kind {
    static let other = DataProcessor.Kind(rawValue: "other")
    static let none = DataProcessor.Kind(rawValue: "none")
    static let capture = DataProcessor.Kind(rawValue: "capture")
    static let serializer = DataProcessor.Kind(rawValue: "serializer")
    static let deserializer = DataProcessor.Kind(rawValue: "deserializer")
    static let networkData = DataProcessor.Kind(rawValue: "networkData")
    static let networkDataOutput = DataProcessor.Kind(rawValue: "networkDataOutput")
    static let networkHelm = DataProcessor.Kind(rawValue: "networkHelm")
    static let networkHelmOutput = DataProcessor.Kind(rawValue: "networkHelmOutput")
}


public protocol DataProcessorProtocol : AnyObject {
    func process(data: Data)
}


public class DataProcessor : DataProcessorProtocol {
    static var shared: DataProcessorProtocol = DataProcessor()
    
    private let prev: DataProcessorProtocol?
    private let next: DataProcessorProtocol?
    weak var nextWeak: DataProcessorProtocol? = nil

    init(next: DataProcessorProtocol? = nil) {
        self.prev = nil
        self.next = next
        self.nextWeak = next
    }

    init(prev: DataProcessorProtocol, next: DataProcessorProtocol? = nil) {
        self.prev = prev
        self.next = next
        self.nextWeak = next
    }
    
    public func process(data: Data) {
        prev?.process(data: data)
        nextWeak?.process(data: data)
    }
}


public extension DataProcessor {
    typealias Base = DataProcessor
    typealias Proto = DataProcessorProtocol
}


extension DataProcessor {
    public struct Kind : Hashable, Equatable, RawRepresentable {
        public init(rawValue: String) { self.rawValue = rawValue }
        public let rawValue: String
    }
}


class DataProcessorBroadcast : DataProcessorProtocol {
    private var array: [DataProcessorProtocol?]
    
    init(_ array: [DataProcessorProtocol?]) {
        self.array = array
    }

    func process(data: Data) {
        for i in array { i?.process(data: data) }
    }
}

public func broadcast(_ x: [DataProcessorProtocol?]) -> DataProcessorProtocol? {
    broadcast(x, create: { DataProcessorBroadcast($0) })
}

public extension DataProcessor {
    class Test : Session.Proto & Flushable.Proto {
        private let data: Data
        private let next: DataProcessorProtocol
        
        public init(next: DataProcessorProtocol, kbits: UInt) {
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

