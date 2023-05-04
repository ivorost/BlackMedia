//
//  NW.Session.swift
//  Core
//
//  Created by Ivan Kh on 08.07.2022.
//

import Foundation
import BlackUtils
#if canImport(UIKit)
import UIKit
#endif


fileprivate extension String {
    static let bonjourServiceName = "_videoNanny._tcp"
}


public extension Network.NW {
    class Session<TInformation: Network.Peer.Information.Proto> {
        public let store: PeerStore<TInformation>
        private let information: TInformation
        private var browser: Browser<TInformation>?
        private var listener: Listener<TInformation>?
        
        public init(information: TInformation = Network.Peer.Information.Basic(Network.Peer.Identity.local)) {
            let peers = PeerStore(local: information)
            self.information = information
            self.store = peers
        }
        
        public func start() async throws {
            try await startInt()

            #if canImport(UIKit)
            await NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground),
                                                         name: UIApplication.didEnterBackgroundNotification,
                                                         object: nil)

            await NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground),
                                                         name: UIApplication.willEnterForegroundNotification,
                                                         object: nil)
            #endif
        }

        private func startInt() async throws {
            let browser = Browser<TInformation>(peers: store,
                                                local: information,
                                                service: .bonjourServiceName)
            let listener = Listener<TInformation>(peers: store,
                                                  identity: information.id,
                                                  service: .bonjourServiceName,
                                                  passcode: "")

            self.browser = browser
            self.listener = listener

            try await listener.start()
            try await browser.start()
        }

        private func stopInt() async {
            await listener?.stop()
            await browser?.stop()
            await store.peers.value.disconnect()

            self.listener = nil
            self.browser = nil
        }

        @objc private func appDidEnterBackground() {
            #if canImport(UIKit)
            let bgTaskID = UIApplication.shared.beginBackgroundTask()

            Task {
                await stopInt()
                await UIApplication.shared.endBackgroundTask(bgTaskID)
            }
            #endif
        }

        @objc private func appWillEnterForeground() {
            Task {
                await tryLog { try await startInt() }
            }
        }
    }
}
