//
//  Peers.Listener.swift
//  Camera
//
//  Created by Ivan Kh on 07.12.2021.
//  Copyright © 2021 Ivan Kh. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import Core
import Bonjour
import RxSwift


fileprivate extension String {
    static let serviceType = "Bonjour"
}


extension Peer.Bonjour {
    class Session {
        let rx = Rx()
        private var bonjour: BonjourSession?
        private let log: Peer.Log.Proto?
        private var peersInternal = [Peer.Bonjour]()
        private var peersHistory = [Peer.Bonjour]()

        init(log: Peer.Log.Proto? = nil) {
            self.log = log
        }
    }
}


extension Peer.Bonjour {
    struct Rx {
        let peers: Observable<[Peer.Proto]>
        fileprivate let peersSubject: BehaviorSubject<[Peer.Proto]>
        
        init() {
            self.peersSubject = .init(value: [])
            self.peers = peersSubject.asObservable()
        }
    }
}


// MARK: - Session
extension Peer.Bonjour.Session : Session.Proto {
    func start() throws {
        let security = BonjourSession.Configuration.Security(identity: nil,
                                                             encryptionPreference: .none,
                                                             invitationHandler: invitationHandler,
                                                             certificateHandler: certificateHandler)

        let config = BonjourSession.Configuration(serviceType: .serviceType,
                                                  peerName: MCPeerID.defaultDisplayName,
                                                  defaults: .standard,
                                                  security: security,
                                                  invitation: .automatic)
        
        bonjour = BonjourSession(configuration: config)
        bonjour?.start()
        bonjour?.onPeerDiscovery = onPeerDiscovery
        bonjour?.onPeerLoss = onPeerLoss
        bonjour?.onPeerConnection = onPeerConnection
        bonjour?.onPeerDisconnection = onPeerDisconnection
        bonjour?.onReceive = onReceive
    }
    
    func stop() {
        bonjour?.stop()
        bonjour = nil
    }
}

// MARK: - Public
extension Peer.Bonjour.Session {
    var peers: [Peer.Proto] {
        return peersInternal
    }
}


fileprivate extension Peer.Bonjour.Session {
    private func invitationHandler(_ bonjourPeer: Bonjour.Peer, _ data: Data?, _ handler: @escaping (Bool) -> Void) {
        let dataString: String
        
        if let data = data {
            dataString = String(data: data, encoding: .utf8) ?? ""
        }
        else {
            dataString = ""
        }
        
        log?.post(peer: peersHistory.firstOrGeneric(bonjourPeer),
                  info: "accepted invitation: \(dataString)")
        
        handler(true)
    }
    
    private func certificateHandler(_ certificate: [Any]?, _ mcPeer: MCPeerID, _ handler: @escaping (Bool) -> Void) {
        if let bonjourPeer = try? Bonjour.Peer(peer: mcPeer, discoveryInfo: nil) {
            log?.post(peer: peersHistory.firstOrGeneric(bonjourPeer), info: "accepted certificate")
        }
        else {
            assert(false)
        }
        
        handler(true)
    }
}


fileprivate extension Peer.Bonjour.Session {
    private func onPeerDiscovery(_ bonjourPeer: Bonjour.Peer) {
        dispatchMainSync {
            let peer: Peer.Bonjour
            
            if let thePeer = peersInternal.first(bonjourPeer) {
                peer = thePeer
            }
            else if let thePeer = peersHistory.first(bonjourPeer) {
                peer = thePeer
                peersInternal.append(peer)
                rx.peersSubject.onNext(peers)
            }
            else {
                peer = Peer.Bonjour(peer: bonjourPeer, session: bonjour)
                peersInternal.append(peer)
                peersHistory.append(peer)
                rx.peersSubject.onNext(peers)
            }
            
            peer.state = .available
            log?.post(peer: peer, info: "found")
        }
    }
    
    private func onPeerLoss(_ bonjourPeer: Bonjour.Peer) {
        dispatchMainSync {
            guard let peer = peersHistory.first(bonjourPeer) else { assertionFailure(); return }
            
            peer.state = .unavailable
            peersInternal.removeFirst(peer)
            log?.post(peer: peer, info: "lost")
            rx.peersSubject.onNext(peers)
        }
    }
    
    private func onPeerConnection(_ bonjourPeer: Bonjour.Peer) {
        dispatchMainSync {
            guard let peer = peersHistory.first(bonjourPeer) else { assertionFailure(); return }
            
            peer.state = .connected
            log?.post(peer: peer, info: "connected")
        }
    }
    
    private func onPeerDisconnection(_ bonjourPeer: Bonjour.Peer) {
        dispatchMainSync {
            guard let peer = peersHistory.first(bonjourPeer) else { assertionFailure(); return }
            
            peer.state = .disconnected
            log?.post(peer: peer, info: "disconnected")
        }
    }
    
    private func onReceive(_ data: Data, _ bonjourPeer: Bonjour.Peer) {
        dispatchMainSync {
            guard let peer = peersHistory.first(bonjourPeer) else { assertionFailure(); return }
            
            peer.get(data)
            log?.post(peer: peer, info: "received \(data.count) bytes")
        }
    }
}
