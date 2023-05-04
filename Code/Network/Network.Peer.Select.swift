//
//  File.swift
//  
//
//  Created by Ivan Kh on 25.04.2023.
//

import Foundation
import Combine
import BlackUtils

fileprivate extension Network.Peer {
    struct FirstConnected<Upstream: Publisher>: Publisher
    where Upstream.Output == [Network.Peer.Proto] {
        typealias Output = Network.Peer.Proto?
        typealias Failure = Upstream.Failure
        let upstream: Upstream

        func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            let bridge = Bridge(downstream: subscriber)
            upstream.subscribe(bridge)
        }
    }
}

fileprivate extension Network.Peer.FirstConnected {
    class Bridge<S>: Subscriber where S: Subscriber, S.Input == Output, S.Failure == Upstream.Failure {
        typealias Input = Upstream.Output
        typealias Failure = Upstream.Failure

        private let downstream: S
        private var peers = Upstream.Output()
        private var peerSubscriptions = [AnyCancellable]()
        private var peer: Network.Peer.Proto?

        init(downstream: S) {
            self.downstream = downstream
        }

        func receive(subscription: Subscription) {
            downstream.receive(subscription: subscription)
        }

        func receive(_ input: Upstream.Output) -> Subscribers.Demand {
            connect(to: input)
            return .unlimited
        }

        func receive(completion: Subscribers.Completion<S.Failure>) {
            downstream.receive(completion: completion)
        }

        private func connect() {
            connect(to: peers)
        }

        private func connect(to peers: Upstream.Output) {
            defer {
                self.peers = peers
            }

            guard peer?.state.value != .connected else { return }

            if let connectedPeer = peers.firstConnected {
                set(connectedPeer)
                return
            }

            let peers2connect = peers.filter { !self.peers.contains($0) }

            Task {
                let connectedPeer = await tryLog {
                    try await peers2connect.connectReturningFirst()
                }

                if let connectedPeer, let connectedPeer {
                    Task {
                        await peers2connect
                            .filter { $0 !== connectedPeer }
                            .disconnect()
                    }
                    
                    set(connectedPeer)
                }
            }
        }

        private func set(_ peer: Network.Peer.Proto) {
            self.peerSubscriptions.cancel()
            self.peer = peer
            _ = self.downstream.receive(peer)
        }
    }
}

public extension Publisher where Self.Output == [Network.Peer.Proto] {
    func firstConnected() -> AnyPublisher<Network.Peer.Proto?, Failure> {
        return Network.Peer.FirstConnected(upstream: self).eraseToAnyPublisher()
    }
}
