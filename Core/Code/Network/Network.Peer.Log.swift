//
//  Peer.swift
//  Camera
//
//  Created by Ivan Kh on 08.12.2021.
//  Copyright © 2021 Ivan Kh. All rights reserved.
//

import Foundation


public protocol PeerLog {
    func post(peer: Network.Peer.Proto, info: String)
}


public extension Network.Peer {
    final class Log : PeerLog {
        static let shared = Log()
        public func post(peer: Network.Peer.Proto, info: String) {}
    }
}


public extension Network.Peer.Log {
    struct Item {
        let peer: Network.Peer.Proto
        let info: String
    }
}


extension Network.Peer.Log.Item : CustomStringConvertible {
    public var description: String {
        return "[\(peer.name)] \(info)"
    }
}


public extension Network.Peer.Log {
    typealias Proto = PeerLog
    typealias ItemsPublisher = Published<[Item]>.Publisher
}


extension Network.Peer.Log {
    class Print : Proto {
        static let shared = Print()
        
        func post(peer: Network.Peer.Proto, info: String) {
            print(Item(peer: peer, info: info))
        }
    }
}


public extension Network.Peer.Log {
    class Publisher : Proto {
        @Published public var items = [Item]()
        
        public init() {}
        
        public func post(peer: Network.Peer.Proto, info: String) {
            items.append(Item(peer: peer, info: info))
        }
    }
}
