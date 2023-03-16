//
//  Swift.Clamping.swift
//  Utils
//
//  Created by Ivan Kh on 08.04.2023.
//

import Foundation

@propertyWrapper
public struct Clamping<Value: Comparable> {
    var value: Value
    let range: ClosedRange<Value>

    public init(wrappedValue value: Value, _ range: ClosedRange<Value>) {
        self.value = value.clamped(range)
        self.range = range
    }

    public var wrappedValue: Value {
        get { value }
        set { value = newValue.clamped(range) }
    }
}

public extension Comparable {
    func clamped(_ range: ClosedRange<Self>) -> Self {
        min(max(range.lowerBound, self), range.upperBound)
    }
}
