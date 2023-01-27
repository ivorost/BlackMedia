//
//  Network.General.swift
//  Utils-macOS
//
//  Created by Ivan Kh on 23.12.2022.
//

import Foundation

public extension Black {
    final class Network {}
}


public protocol BlackNetworkSessionProtocol {
    var queue: DispatchQueue? { get }
    func start(on queue: DispatchQueue)
    func start(on queue: DispatchQueue) async throws
    func stop()
    func stop() async
}


public extension Black.Network {
    typealias SessionProtocol = BlackNetworkSessionProtocol
}
