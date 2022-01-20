//
//  Peer.swift
//  Camera
//
//  Created by Ivan Kh on 08.12.2021.
//  Copyright © 2021 Ivan Kh. All rights reserved.
//

import Foundation
import RxSwift


protocol PeerLog {
    func post(peer: Peer.Proto, info: String)
}


extension Peer {
    final class Log : PeerLog {
        static let shared = Log()
        func post(peer: Peer.Proto, info: String) {}
    }
}


extension Peer.Log {
    struct Item {
        let peer: Peer.Proto
        let info: String
    }
}


extension Peer.Log.Item : CustomStringConvertible {
    var description: String {
        return "[\(peer.name)] \(info)"
    }
}


extension Peer.Log {
    typealias Proto = PeerLog
}


extension Peer.Log {
    class Print : Proto {
        static let shared = Print()
        
        func post(peer: Peer.Proto, info: String) {
            print(Item(peer: peer, info: info))
        }
    }
}


extension Peer.Log {
    class BehaviorSubject : Proto {
        let items = RxSwift.BehaviorSubject<[Item]>(value: [])
        private var itemsInternal = [Item]()
        
        func post(peer: Peer.Proto, info: String) {
            itemsInternal.append(Item(peer: peer, info: info))
            items.onNext(itemsInternal)
        }
    }
}
