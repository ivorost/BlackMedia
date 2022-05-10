//
//  Network.Peer.swift
//  Core
//
//  Created by Ivan Kh on 20.04.2022.
//

import Foundation
import Bonjour


public extension Network {
    final class Peer {}
}


public protocol PeerProtocol {
    var id: String { get }
    var name: String { get }
    var state: Network.Peer.State { get }
    
    func connect()
    func disconnect()
    
    func put(_ data: Data)
    func get(_ data: Data)
}


public extension Network.Peer {
    typealias Proto = PeerProtocol
}


public extension Network.Peer {
    enum State {
        case unavailable
        case available
        case connecting
        case connected
        case disconnecting
        case disconnected
    }
}


public extension Network.Peer.State {
    func isGood() -> Bool {
        return self == .available || self == .connected || self == .connecting
    }

    func isBad() -> Bool {
        return !isGood()
    }
}

