//
//  Foundation.Data.swift
//  Capture
//
//  Created by Ivan Kh on 09.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

public extension Data {
    func bytes(_ body: (UnsafeRawPointer) -> Void) {
        withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            if let baseAddress = bytes.baseAddress {
                body(baseAddress)
            }
        }
    }
}
