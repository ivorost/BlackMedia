//
//  Peer.Bonjour.Model.swift
//  Camera
//
//  Created by Ivan Kh on 20.01.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import Foundation
import Bonjour


typealias BonjourPeer = Bonjour.Peer


extension Peer {
    class Bonjour : Peer.Base {
        init(_ peer: BonjourPeer) {
            super.init(id: peer.id)
            self.name = peer.name
        }
    }
}


extension Peer.Base {
    convenience init(bonjour peer: BonjourPeer) {
        self.init(id: peer.id)
        name = peer.name
    }
}


extension Array where Element : Peer.Proto {
    func first(_ peer: BonjourPeer) -> Element? {
        return first(id: peer.id)
    }
    
    func firstOrGeneric(_ peer: BonjourPeer) -> Peer.Proto {
        return first(peer) ?? Peer.Base(bonjour: peer)
    }
}
