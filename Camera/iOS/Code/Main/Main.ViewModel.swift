//
//  Main.ViewModel.swift
//  Camera
//
//  Created by Ivan Kh on 11.08.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import Foundation
import UIKit
import Combine

extension Main {
    class ViewModel : ObservableObject {
//        let peerSelector: Peer.Selector.General
        let peerSelector: Peer.Selector.GeneralTest = .init()
        private let nwSession = Network.NW.Session()
        private let peersLog = Network.Peer.Log.Publisher()
        private let put: Peer.Put
        private(set) var select = Select.ViewModel()

        init() {
//            peerSelector
//            = Peer.Selector.General(peers: nwSession.peers.peers.receive(on: RunLoop.main).eraseToAnyPublisher())

            put
            = Peer.Put(peerSelector)

            select
            = Select.ViewModel(peers: nwSession.peers.peers, selector: peerSelector, logs: peersLog.$items)
        }
        
        func start() async throws {
            try await nwSession.start()
        }
    }
}
