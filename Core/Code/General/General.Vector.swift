//
//  General.Vector.swift
//  Capture
//
//  Created by Ivan Kh on 26.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation


public protocol ProcessorWithVectorProtocol {
    associatedtype T
    func create() -> [T]
    func append(_ element: T)
    func prepend(_ element: T)
}


public class ProcessorWithVector<T> : ProcessorWithVectorProtocol {
    private(set) var vector: [T]

    init() {
        self.vector = []
        self.vector = create()
    }
    
    init(_ vector: [T]) {
        self.vector = vector
    }
    
    public func create() -> [T] {
        return []
    }

    public func prepend(_ element: T) {
        vector.insert(element, at: 0)
    }
    
    public func append(_ element: T) {
        vector.append(element)
    }
}
