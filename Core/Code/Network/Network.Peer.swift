//
//  Network.Peer.swift
//  Core
//
//  Created by Ivan Kh on 20.04.2022.
//

import Foundation
import Combine


public extension Network {
    final class Peer {}
}


public protocol PeerProtocol {
    #if DEBUG
    var debugIdentifier: Int { get }
    #endif

    var id: String { get }
    var name: String { get }
    var state: Network.Peer.State { get }
    var get: AnyPublisher<Data, Never> { get }
    
    func connect() async throws -> Bool
    func disconnect() async
    func put(_ data: Data)
}


public extension Network.Peer {
    typealias Proto = PeerProtocol
    typealias PeersPublisher = Published<[Proto]>.Publisher
}


public extension Network.Peer {
    // Order better ascending
    enum State : Int {
        case unavailable
        case available
        case disconnected
        case disconnecting
        case connecting
        case connected
    }
}


public extension Network.Peer.State {
    func isGood() -> Bool {
        return self == .available || self == .connected || self == .connecting
    }
    
    func isBad() -> Bool {
        return !isGood()
    }
    
    static func better(_ s1: Network.Peer.State, _ s2: Network.Peer.State) -> Network.Peer.State {
        return s1.rawValue > s2.rawValue
        ? s1
        : s2
    }
}


public extension Array where Element == Network.Peer.Proto {
    func sortedByState() -> Array {
        return sorted { $0.state.rawValue > $1.state.rawValue }
    }
}
