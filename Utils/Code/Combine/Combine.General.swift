//
//  Combine.GEneral.swift
//  Utils
//
//  Created by Ivan Kh on 13.01.2023.
//

import Combine

public extension Array where Element : AnyCancellable {
    mutating func cancel() {
        forEach { $0.cancel() }
        removeAll()
    }
}
