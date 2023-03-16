//
//  NW.Session.swift
//  Core
//
//  Created by Ivan Kh on 08.07.2022.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif


fileprivate extension String {
    static let bonjourServiceName = "_videoNanny._tcp"
}


extension UserDefaults {
    var endpointID: String {
        if let result = string(forKey: "endpointID") {
            return result
        }
        else {
            let result = Network.NW.EndpointName.generateID
            setValue(result, forKey: "endpointID")
            synchronize()
            return result
        }
    }
}


extension Network.NW.EndpointName {
    static let current = Network.NW.EndpointName(pin: UserDefaults.standard.endpointID,
                                                 name: Device.name,
                                                 kind: .current)
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
        
        public func start() async throws {
            try await listener.start()
            try await browser.start()
        }
    }
}
