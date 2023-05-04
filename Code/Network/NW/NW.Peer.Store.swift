//
//  File.swift
//  
//
//  Created by Ivan Kh on 19.04.2023.
//

import Foundation
import Combine
import Network
import BlackUtils

public extension Network.NW {
    class PeerStore<TInformation: Network.Peer.Information.Proto>: ObservableObject {
        public  var peers: AnyValuePublisher<[Network.Peer.AnyProto], Never> { peersSubject.eraseToAnyValuePublisher() }
        private let peersSubject = CurrentValueSubject<[Network.Peer.AnyProto], Never>([])
        private var allPeers = [Network.Peer.Proxy]()
        private let localInfo: TInformation

        init(local info: TInformation) {
            localInfo = info
        }

        func received(connection: Connection, for information: Network.Peer.Information.AnyProto) async {
            await inboundPeer(information) { peer in
                peer.add(inbound: connection)
            }
        }

        func received(peers: [Peer]) async {
            var allPeers = allPeers

            allPeers.forEach { peer in
                if !peers.contains(where: { $0.id.unique == peer.id.unique }) {
                    (peer.inner as? PeerBase)?.set(available: false)
                }
            }

            for peer in peers {
                guard let existingPeer = allPeers.first(peer.id) else {
                    peer.set(available: true)
                    allPeers.append(.init(peer))
                    continue
                }

                if !existingPeer.available.value {
                    (existingPeer.inner as? PeerBase)?.set(available: true)
                }

                if let inboundPeer = existingPeer.inner as? InboundPeer {
                    peer.setInbound(from: inboundPeer)
                    existingPeer.inner = peer
                }
            }

            debugPrint("PeerStore: received \(peers)")
            set(peers: allPeers)
        }

        private func inboundPeer(_ remote: Network.Peer.Information.AnyProto, action: (PeerBase) async -> Void) async {
            if let peer = allPeers.first(remote.id)?.inner as? PeerBase {
                await action(peer)
                return
            }

            // add inbound peer if can't find existing

            let peer = InboundPeer(local: localInfo, remote: remote)
            var allPeers = allPeers

            await action(peer)
            allPeers.append(.init(peer))
            set(peers: allPeers)
            debugPrint("PeerStore: added temporary \(allPeers)")
        }

        private func set(peers: [Network.Peer.Proxy]) {
            allPeers = peers
            peersSubject.send(peers)
        }
    }
}
