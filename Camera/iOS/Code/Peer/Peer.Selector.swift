//
//  Peer.Selector.swift
//  Camera
//
//  Created by Ivan Kh on 22.04.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import Foundation
import Combine


final class Peer {}


extension Peer {
    class Selector {
        @Published private(set) var peer: Network.Peer.Proto?
        private var peers: [Network.Peer.Proto] = []
        private var peersSubscription: AnyCancellable?
        private let peersPublisher: AnyPublisher<[Network.Peer.Proto], Never>
        private let queue = TaskQueue()

        convenience init() {
            self.init(peers: Empty(completeImmediately: false).eraseToAnyPublisher())
        }
        
        init(peers: AnyPublisher<[Network.Peer.Proto], Never>) {
            peersPublisher = peers
            peersSubscription = peers.sink(receiveValue: peers(value:))
        }
        
        private func peers(value: [Network.Peer.Proto]) {
            self.peers = value
            select()
        }
        
        private func select() {
            queue.task {
                let oldPeer = self.peer
                guard self.peer?.state.value != .connected else { return }
                guard let newPeer = self.peers.sortedByState().first else { return }

                do {
                    #if DEBUG
                    print("Selector: selecting peer \(newPeer.debugIdentifier)")
                    #endif
                    
                    if newPeer.state.value != .connected {
                        _ = try await newPeer.connect()
                    }

                    print("STATE in SELECTOR \(newPeer.state.value)")

                    if newPeer.state.value == .connected {
                        self.peer = newPeer

                        if newPeer !== oldPeer {
                            Task {
                                await oldPeer?.disconnect()
                            }
                        }

                        #if DEBUG
                        print("Selector: set peer \(newPeer.debugIdentifier)")
                        #endif
                    }
                }
                catch {
                    print("Selector: connection error \(error)")
                }
            }
        }
    }
}
