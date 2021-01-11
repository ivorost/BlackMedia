//
//  Network.Packet.swift
//  Capture
//
//  Created by Ivan Kh on 02.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

class PacketSerializer {
    
    var data = Data()
    
    func push(_ value: UnsafeRawPointer, _ size: Int) {
        var size32 = UInt32(size)
        
        withUnsafeBytes(of: &size32) { data.append($0.bindMemory(to: UInt8.self)) }
        data.append(UnsafeBufferPointer(start: value.bindMemory(to: UInt8.self, capacity: size), count: size))
    }

    func push(data: Data) {
        data.bytes {
            push($0, data.count)
        }
    }

    func push(data: NSData) {
        push(data.bytes, data.length)
    }

    func push(string: String) {
        push(data: string.data(using: .utf8)! as NSData)
    }
    
    func push<T>(array: [T]?) {
        var size32 = UInt32((array != nil ? array!.count : 0) * MemoryLayout<T>.size)
        
        withUnsafeBytes(of: &size32) { data.append($0.bindMemory(to: UInt8.self)) }
        
        guard size32 != 0 else { return }

        for var i in array! {
            withUnsafeBytes(of: &i) { data.append($0.bindMemory(to: UInt8.self)) }
        }
    }
}

class PacketDeserializer {
    private let data: Data
    private(set) var shift = 0
    
    init(_ data: Data) {
        self.data = data
    }
    
    convenience init(_ data: Data, _ index: Int) {
        self.init(data)
        
        for _ in 0 ..< index {
            _ = popSkip()
        }
    }

    private func popSize() -> Int {
        var size: UInt32 = 0
        
        _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            memcpy(&size, bytes.bindMemory(to: UInt8.self).baseAddress?.advanced(by: shift), MemoryLayout<UInt32>.size)
        }
        
        shift += MemoryLayout<UInt32>.size
        
        return Int(size)
    }
    
    func pop(_ value: UnsafeMutableRawPointer) {
        let size = popSize()

        _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            memcpy(value, bytes.bindMemory(to: UInt8.self).baseAddress?.advanced(by: shift), size)
        }

        shift += size
    }
    
    func pop<T: InitProtocol>(array: inout [T]?) {
        let size = popSize()
        if size == 0 { return }
        var i = 0
        
        array = [T]()
        
        while i < size {
            var x = T()
            
            _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                memcpy(&x, bytes.bindMemory(to: UInt8.self).baseAddress?.advanced(by: shift), MemoryLayout<T>.size)
            }

            array!.append(x)
            
            i += MemoryLayout<T>.size
            shift += MemoryLayout<T>.size
        }
    }
    
    func pop(data: inout Data?) {
        let size = popSize()
        let resultBytes = malloc(size)!
        
        _ = self.data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            memcpy(resultBytes, bytes.bindMemory(to: UInt8.self).baseAddress?.advanced(by: shift), Int(size))
        }

        shift += Int(size)
        data = Data(bytesNoCopy: resultBytes, count: size, deallocator: .free)
    }
    
    func popData() -> Data {
        var result: Data?
        pop(data: &result)
        return result!
    }
    
    func popString() -> String {
        return String(data: popData(), encoding: .utf8)!
    }
    
    func popSkip() -> PacketDeserializer {
        shift = popSize() + shift
        return self
    }
}
