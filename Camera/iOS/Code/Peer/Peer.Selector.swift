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
    final class Selector {}
}

protocol PeerSelectorProtocol : ObservableObject {
    var peer: Network.Peer.Pair.Proto? { get }
    var peerPublisher: Published<Network.Peer.Pair.Proto?>.Publisher { get }
}

extension Peer.Selector {
    typealias Proto = PeerSelectorProtocol
}

extension Peer.Selector {
    class General : PeerSelectorProtocol {
        private var peers: [Network.Peer.Proto] = []
        private var peerSubscription: AnyCancellable?
        private var peersSubscription: AnyCancellable?
        private let peersPublisher: AnyPublisher<[Network.Peer.Proto], Never>
        private let queue = TaskQueue()

        @Published private(set) var peer: Network.Peer.Pair.Proto?
        @Published private(set) var connectedPeer: Network.Peer.Pair.Proto?
        var peerPublisher: Published<Network.Peer.Pair.Proto?>.Publisher { $peer }

        init() {
            peersPublisher = Empty(completeImmediately: false).eraseToAnyPublisher()
            setup(peers: peersPublisher)
        }
        
        init(peers: AnyPublisher<[Network.Peer.Proto], Never>) {
            peersPublisher = peers
            setup(peers: peers)
        }

        private func setup(peers: AnyPublisher<[Network.Peer.Proto], Never>) {
            peersSubscription = peers.sink(receiveValue: peers(value:))
        }
        
        private func peers(value: [Network.Peer.Proto]) {
            self.peers = value
            select()
        }

        @MainActor private func set(peer: Network.Peer.Pair.Proto) {
            guard self.peer?.remote !== peer.remote else { return }

            self.peerSubscription?.cancel()
            self.peer = peer

            if peer.remote.state.value == .connected {
                self.connectedPeer = peer
            }

            peerSubscription = peer.remote.state.sink { state in
                if state == .connected {
                    self.connectedPeer = peer
                }
                else {
                    self.connectedPeer = nil
                }
            }
        }

        private func select() {
            queue.task {
                let oldPeer = self.peer
                guard self.peer?.remote.state.value != .connected else { return }

                let localPeers = self.peers
                    .sortedByState()
                    .compactMap { Network.Peer.Pair.General($0) }
                    .filter { $0.state.value != .skipped }
                    .sortedByPaired

                guard let newPeer = localPeers.first else { return }

                do {
                    debugPrint("Selector: selecting peer \(newPeer.remote.debugIdentifier)")

                    if newPeer.remote.state.value != .connected {
                        _ = try await newPeer.remote.connect()
                    }

                    debugPrint("STATE in SELECTOR \(newPeer.remote.state.value)")

                    if newPeer.remote.state.value == .connected && newPeer.remote !== oldPeer?.remote {
                        await self.set(peer: newPeer)

                        Task {
                            await oldPeer?.remote.disconnect()
                        }

                        debugPrint("Selector: set peer \(newPeer.remote.debugIdentifier)")
                    }
                }
                catch {
                    debugPrint("Selector: connection error \(error)")
                }
            }
        }
    }
}


extension Peer.Selector {
    class Test: Proto {
        @Published var peer: Core.Network.Peer.Pair.Proto?
        var peerPublisher: Published<Network.Peer.Pair.Proto?>.Publisher { $peer }

        init() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                let peer = Network.Peer.Generic()
                peer.kind = .iPhone
                peer.name = "Test phone #1"
                peer.id = "test_iphone_id_1"
                peer.stateSubject.send(.connected)
                self.peer = Network.Peer.Pair.General(peer)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                let peer = Network.Peer.Generic()
                peer.kind = .iPad
                peer.name = "Test tablet #1"
                peer.id = "test_ipad_id_1"
                peer.stateSubject.send(.connected)
                self.peer = Network.Peer.Pair.General(peer)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.peer = nil
            }
        }


    }
}

extension Peer.Selector {
    class GeneralTest: General {
        private var publisher = PassthroughSubject<[Network.Peer.Proto], Never>()

        override init() {
            super.init(peers: publisher.eraseToAnyPublisher())
            test1()
        }

        func test1() {
            let peers: [Network.Peer.Generic] = [ .init(id: "test_iphone_id_1",
                                                        name: "Test iPhone #1",
                                                        kind: .iPhone,
                                                        state: .connected),
                                                  .init(id: "test_ipad_id_1",
                                                        name: "Test tablet #1",
                                                        kind: .iPad,
                                                        state: .connected)]

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.publisher.send(peers)
            }
        }
    }
}

extension Array where Element: Network.Peer.Pair.Proto {
    var sortedByPaired: [Element] {
        sorted {
            if $0.state.value == .paired {
                return true
            }

            if $1.state.value == .paired {
                return false
            }

            return true
        }
    }
}
