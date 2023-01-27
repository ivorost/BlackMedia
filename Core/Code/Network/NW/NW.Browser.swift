/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Create a class to browse for game peers using Bonjour.
*/

import Network
import Utils
import Combine

public extension Network.NW {
    class Browser {
        let inner: Black.Network.Browser
        private let endpointName: EndpointName
        private let peers: PeerStore
        private var cancellables = [AnyCancellable]()
        private let queue = TaskQueue()

        public init(peers: PeerStore, endpoint endpointName: EndpointName, service serviceName: String) {
            self.peers = peers
            self.endpointName = endpointName
            self.inner = .init(NWBrowser(for: .bonjour(type: serviceName, domain: nil),
                                         using: NWParameters(includePeerToPeer: true)))
        }
        
        public func start(on queue: DispatchQueue = .global()) async throws {
            inner.state.sink(receiveValue: state(changed:)).store(in: &cancellables)
            inner.update.sink(receiveValue: update(to:)).store(in: &cancellables)
            try await inner.start(on: queue)
        }
        
        public func stop() async {
            await inner.stop()
            cancellables.cancel()
        }
        
        private func state(changed to: NWBrowser.State) {
            switch to {
            case .failed(let error):
                // Restart the browser if it loses its connection
                if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
                    inner.restart()
                }
                else {
                    inner.stop()
                }
                
            case .ready:
                self.update(to: Array(inner.inner.browseResults))

            case .cancelled:
                self.update(to: [])
                
            default:
                break
            }
        }
        
        private func update(to: Black.Network.Browser.Update) {
            update(to: Array(to.peers))
        }
        
        private func update(to peers: [Peer]) {
            let filtered = Array(peers).removing(enpoint: endpointName)
            
            queue.task {
                await self.peers.received(peers: filtered)
            }
        }
    }
}
