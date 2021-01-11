//
//  General.Vector.swift
//  Capture
//
//  Created by Ivan Kh on 26.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

protocol ProcessorWithVectorProtocol {
    associatedtype T
    func create() -> [T]
    func register(_ element: T)
}

class ProcessorWithVector<T> : ProcessorWithVectorProtocol {
    private(set) var vector: [T]

    init() {
        self.vector = []
        self.vector = create()
    }
    
    init(_ vector: [T]) {
        self.vector = vector
    }
    
    func create() -> [T] {
        return []
    }

    func register(_ element: T) {
        vector.append(element)
    }
}
