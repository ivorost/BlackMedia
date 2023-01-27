//
//  Combine.Publisher.swift
//  Utils
//
//  Created by Ivan Kh on 20.01.2023.
//

import Combine

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher {
    public var map: Publishers.Map<Self, Void> {
        return map { _ in }
    }
}
