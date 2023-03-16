//
//  Foundation.Pointers.swift
//  Utils
//
//  Created by Ivan Kh on 04.02.2023.
//

import Foundation

public extension UnsafeMutableBufferPointer {
    func fill(with value: Element) {
        for i in 0 ..< count {
            self[i] = value
        }
    }
}
