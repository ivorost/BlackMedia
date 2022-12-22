//
//  NW.Session.swift
//  Core
//
//  Created by Ivan Kh on 08.07.2022.
//

import Foundation
import UIKit


fileprivate extension String {
    static let bonjourServiceName = "_videoNanny._tcp"
    static let deviceID = UIDevice.current.name
}


extension Network.NW.EndpointName {
    static let current = Network.NW.EndpointName.encode(.deviceID)
    static let currentData = current.encoded.data(using: .utf8)
}


public extension Network.NW {
    class Session {
        public let peers: PeerStore
        private let browser: Browser
        private let listener: Listener
        
        public init() {
            let peers = PeerStore()
            let browser = Browser(peers: peers,
                                  endpoint: EndpointName.current,
                                  service: .bonjourServiceName)
            let listener = Listener(peers: peers,
                                    endpoint: EndpointName.current,
                                    service: .bonjourServiceName,
                                    passcode: "")
            
            self.peers = peers
            self.browser = browser
            self.listener = listener
        }
        
        public func start() throws {
            Task {
                try await listener.start()
                browser.start()
            }
        }
    }
}
