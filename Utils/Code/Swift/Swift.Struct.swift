//
//  Swift.Struct.swift
//  Capture
//
//  Created by Ivan Kh on 02.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

public protocol StructProtocol : InitProtocol {

    init(deserialize data: Data)

    var data: Data { get }
}

public extension StructProtocol {
    
    init(deserialize data: Data) {
        self.init()

        data.bytes {
            memcpy(&self, $0, MemoryLayout<Self>.size)
        }
    }
 
    var data: Data {
        var copy = self
        return Data(bytes: &copy, count: MemoryLayout<Self>.size)
    }
}

public class StructContainer<T> {
    public let inner: T
    
    public init(_ inner: T) {
        self.inner = inner
    }
}
