//
//  Network.Packet.swift
//  Capture
//
//  Created by Ivan Kh on 02.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation
import BlackUtils

public extension Network {
    struct PacketSerializer {
        private(set) var data = Data()

        init(type: PacketType, id: UInt64) {
            push(raw: type.rawValue)
            push(raw: id)
        }
        
        private mutating func push(block value: UnsafeRawPointer, size: Int) {
            var size32 = UInt32(size)
            
            withUnsafeBytes(of: &size32) { data.append($0.bindMemory(to: UInt8.self)) }
            data.append(UnsafeBufferPointer(start: value.bindMemory(to: UInt8.self, capacity: size), count: size))
        }

        mutating func push<T: Numeric>(raw value: T) {
            data.encode(value)
        }

        mutating func push(raw data: Data) {
            self.data += data
        }

        mutating func push(raw value: BinaryCodable) {
            push(raw: value.data)
        }

        mutating func push(block data: Data) {
            data.bytes {
                push(block: $0, size: data.count)
            }
        }
        
        mutating func push(block data: NSData) {
            push(block: data.bytes, size: data.length)
        }
        
        mutating func push(block string: String) {
            push(block: string.data(using: .utf8)!)
        }
        
        mutating func push<T>(block value: T) {
            var valueVar = value
            push(block: &valueVar, size: MemoryLayout<T>.size)
        }
        
        mutating func push<T>(block array: [T]?) {
            var size32 = UInt32((array != nil ? array!.count : 0) * MemoryLayout<T>.size)
            
            withUnsafeBytes(of: &size32) { data.append($0.bindMemory(to: UInt8.self)) }
            
            guard size32 != 0 else { return }
            
            for var i in array! {
                withUnsafeBytes(of: &i) { data.append($0.bindMemory(to: UInt8.self)) }
            }
        }
    }
}

public extension Network {
    struct PacketDeserializer {
        private(set) var type: PacketType = .undefined
        private(set) var id: UInt64 = 0

        private var data: Data

        init(_ data: Data) throws {
            self.data = data
            self.type = PacketType(rawValue: try raw(UInt8.self)) ?? .undefined
            self.id = try raw(UInt64.self)
        }
        
        init(_ data: Data, _ index: Int) throws {
            try self.init(data)
            
            for _ in 0 ..< index {
                _ = try blockSkip()
            }
        }
        
        private mutating func popSize() throws -> Int {
            return Int(try data.pop(UInt32.self))
        }
        
        private mutating func pop(_ value: UnsafeMutableRawPointer) throws {
            let size = try popSize()
            
            _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                memcpy(value, bytes.bindMemory(to: UInt8.self).baseAddress, Int(size))
            }

            data = data[(data.startIndex + size)...]
        }
        
//        private func pop<T: InitProtocol>(array: inout [T]?) {
//            let size = popSize()
//            if size == 0 { return }
//            var i = 0
//
//            array = [T]()
//
//            while i < size {
//                var x = T()
//
//                _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
//                    memcpy(&x, bytes.bindMemory(to: UInt8.self).baseAddress?.advanced(by: shift), MemoryLayout<T>.size)
//                }
//
//                array!.append(x)
//
//                i += MemoryLayout<T>.size
//                shift += MemoryLayout<T>.size
//            }
//        }
        
        private mutating func popBlock() throws -> Data {
            let size = try popSize()
            guard data.count >= size else { throw Data.CodingError.outOfMemory }
            let result = data.prefix(size)

            data = data[(data.startIndex + size)...]
            return result
        }
        
        mutating func blockData() throws -> Data {
            return try popBlock()
        }
        
        mutating func blockString() throws -> String {
            return String(data: try blockData(), encoding: .utf8)!
        }
        
        mutating func blockSkip() throws -> PacketDeserializer {
            data = data[try popSize()...]
            return self
        }

        mutating func raw<T: Numeric>(_ type: T.Type) throws -> T {
            try data.pop(type)
        }

        mutating func raw<T: BinaryDecodable>(_ type: T.Type) throws -> T {
            try T.init(from: &data)
        }
    }
}


public extension Network.PacketSerializer {
    class Processor: Data.Producer.Proto {
        public var next: Data.Processor.AnyProto?
        
        init(next: Data.Processor.AnyProto = Data.Processor.shared) {
            self.next = next
        }
        
        func process(packet: Network.PacketSerializer) {
            next?.process(packet.data)
        }
    }
}


public extension Network.PacketDeserializer {
    class Processor : Data.Processor.Proto {
        private let type: Network.PacketType?

        init(type: Network.PacketType? = nil) {
            self.type = type
        }
        
        public func process(_ data: Data) {
            tryLog {
                var packet = try Network.PacketDeserializer(data)
                guard type == nil || packet.type == type else { return }
                try process(packet: &packet)
            }
        }
        
        func process(packet: inout Network.PacketDeserializer) throws {
            // to override
        }
    }
}
