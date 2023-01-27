//
//  Select.ViewModel.swift
//  Camera
//
//  Created by Ivan Kh on 11.08.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import Foundation
import Combine

extension Select {
    class ViewModel : ObservableObject {
        @MainActor @Published var peers = [Network.Peer.Proto]()
        @MainActor @Published var logs = [Network.Peer.Log.Item]()
        private(set) var trace = Trace.ViewModel()
        let selector: Peer.Selector

        init() {
            self.selector = Peer.Selector()
            self.trace = Trace.ViewModel(peers: $peers.eraseToAnyPublisher(), logs: $logs)
        }
        
        init(peers: Network.Peer.PeersPublisher,
             selector: Peer.Selector,
             logs: Network.Peer.Log.ItemsPublisher) {
            self.selector = selector
            peers.receive(on: RunLoop.main).assign(to: &self.$peers)
            logs.assign(to: &self.$logs)
            self.trace = Trace.ViewModel(peers: self.$peers.eraseToAnyPublisher(), logs: logs)
        }
    }
}
