//
//  Trace.ViewModel.swift
//  Camera
//
//  Created by Ivan Kh on 11.08.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import Foundation
import Combine

extension Trace {
    class ViewModel : ObservableObject {
        @MainActor @Published var peers = [Network.Peer.Proto]()
        @MainActor @Published var logs = [Network.Peer.Log.Item]()

        init() {
        }
        
        init(peers: Network.Peer.PeersPublisher, logs: Network.Peer.Log.ItemsPublisher) {
            peers.assign(to: &self.$peers)
            logs.assign(to: &self.$logs)
        }
    }
}
