//
//  Swift.Struct.swift
//  Capture
//
//  Created by Ivan Kh on 02.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

protocol StructProtocol : InitProtocol {

    init(deserialize data: NSData)

    func nsData() -> NSData
}

extension StructProtocol {
    
    init(deserialize data: NSData) {
        self.init()
        memcpy(&self, data.bytes, MemoryLayout<Self>.size)
    }
 
    func nsData() -> NSData {
        var copy = self
        return NSData(bytes: &copy, length: MemoryLayout<Self>.size)
    }
}
