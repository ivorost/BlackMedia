//
//  Peer.Bonjour.Model.swift
//  Camera
//
//  Created by Ivan Kh on 20.01.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import Foundation
import Bonjour
import UIKit


typealias BonjourPeer = Bonjour.Peer


extension Peer {
    class Bonjour : Peer.Base {
        private let peer: BonjourPeer
        private weak var session: BonjourSession?
        
        init(peer: BonjourPeer, session: BonjourSession?) {
            self.peer = peer
            self.session = session
            
            super.init(id: peer.id)
            self.name = peer.name
        }

        override func put(_ data: Data) {
            super.put(data)
            session?.send(data, to: [peer])
        }
        
        override func connect() {
            super.connect()
            
            session?.invite(peer, with: UIDevice.current.ipAddress?.data(using: .utf8), timeout: 5) { result in
                switch result {
                case .failure(let error):
                    print(error)
                    break
                case .success(let result):
                    assert(result.id == self.peer.id)
                }
            }
        }
        
        override func disconnect() {
            super.disconnect()
            state = .disconnected // doesn't support disconnecting
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
