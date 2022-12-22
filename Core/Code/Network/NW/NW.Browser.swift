/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Create a class to browse for game peers using Bonjour.
*/

import Network


public extension Network.NW {
    class Browser {
        private var browser: NWBrowser?
        private let serviceName: String
        private let endpointName: EndpointName
        private let peers: PeerStore

        public init(peers: PeerStore, endpoint endpointName: EndpointName, service name: String) {
            self.peers = peers
            self.endpointName = endpointName
            self.serviceName = name
        }
        
        // Start browsing for services.
        public func start() {
            // Create parameters, and allow browsing over peer-to-peer link.
            let parameters = NWParameters()
            parameters.includePeerToPeer = true
            
            // Browse for a custom service type.
            let browser = NWBrowser(for: .bonjour(type: serviceName, domain: nil), using: parameters)
            self.browser = browser
            browser.stateUpdateHandler = { newState in
                switch newState {
                case .failed(let error):
                    // Restart the browser if it loses its connection
                    if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
                        print("Browser: failed with \(error), restarting")
                        browser.cancel()
                        self.start()
                    } else {
                        print("Browser: failed with \(error), stopping")
//                        self.delegate?.displayBrowseError(error)
                        browser.cancel()
                    }
                case .ready:
                    print("Browser: ready")
                    // Post initial results.
                    self.update(peers: Array(browser.browseResults))
//                    self.delegate?.refreshResults(results: Array(browser.browseResults))
                case .cancelled:
                    print("Browser: cancelled")
                    self.update(peers: [])
//                    self.delegate?.refreshResults(results: [])
                    break
                default:
                    print("Browser: Unknown state \(newState)")
                    break
                }
            }
            
            // When the list of discovered endpoints changes, refresh the delegate.
            browser.browseResultsChangedHandler = { results, changes in
                self.update(peers: Array(results))
            }
            
            // Start browsing and ask for updates on the main queue.
            browser.start(queue: .global())
        }
        
        private func update(peers: [Peer]) {
            let filtered = peers.removing(enpoint: endpointName)
            self.peers.received(peers: filtered)
            print("BROWSE: \(filtered)")
        }
    }
}
