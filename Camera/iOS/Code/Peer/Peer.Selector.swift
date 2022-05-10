//
//  Peer.Selector.swift
//  Camera
//
//  Created by Ivan Kh on 22.04.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import Foundation
import RxSwift


extension Peer {
    class Selector {
        private(set) var peer: Peer.Proto?
        private var peers: [Peer.Proto] = []
        private let bag = DisposeBag()
        let rx: Rx
        private let rxPeer: BehaviorSubject<Peer.Proto?>

        init(peers: BehaviorSubject<[Peer.Proto]>) {
            rxPeer = BehaviorSubject<Peer.Proto?>(value: nil)
            rx = Rx(peer: rxPeer)
            peers.subscribe(peers(event:)).disposed(by: bag)
        }
        
        private func peers(event: RxSwift.Event<[Peer.Proto]>) {
            guard let newPeers = event.element else { return }
            
            self.peers = newPeers
            
            if let peer = newPeers.first, self.peer == nil {
                self.peer = peer
                peer.connect()
                rxPeer.onNext(peer)
            }
        }
    }
}


extension Peer.Selector {
    struct Rx {
        let peer: Observable<Peer.Proto?>
    }
}
