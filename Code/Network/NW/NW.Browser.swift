/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Create a class to browse for game peers using Bonjour.
*/

import Network
import Combine
import BlackUtils

public extension Network.NW {
    class Browser<TInformation: Network.Peer.Information.Proto> {
        let inner: Black.Network.Browser
        private let local: TInformation
        private let peers: PeerStore<TInformation>
        private var cancellables = [AnyCancellable]()
        private let queue = TaskQueue()

        public init(peers: PeerStore<TInformation>, local: TInformation, service serviceName: String) {
            self.peers = peers
            self.local = local
            self.inner = .init(NWBrowser(for: .bonjourWithTXTRecord(type: serviceName, domain: nil),
                                         using: NWParameters(includePeerToPeer: true)))
        }
        
        public func start(on queue: DispatchQueue = .global()) async throws {
            inner.state.sink(receiveValue: state(changed:)).store(in: &cancellables)
            inner.update.sink(receiveValue: update(_:)).store(in: &cancellables)
            try await inner.start(on: queue)
        }
        
        public func stop() async {
            await inner.stop()
            await peers.received(peers: [])
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
                self.update(to: inner.inner.browseResults)

            case .cancelled:
                self.update(to: [])
                
            default:
                break
            }
        }

        private func update(_ update: Black.Network.Browser.Update) {
            self.update(to: update.peers)
        }

        private func update(to: Set<NWBrowser.Result>) {
            update(to: Array(remote: to, local: local))
        }

        private func update(to peers: [Peer]) {
            let filtered = Array(peers).removing(local.id)
            
            queue.task {
                guard self.inner.inner.state != .cancelled else { return }
                await self.peers.received(peers: filtered)
            }
        }
    }
}

fileprivate extension Array where Element == Network.NW.Peer {
    init<S: Sequence>(remote: S, local: Network.Peer.Information.AnyProto) where S.Element == NWBrowser.Result {
        let result = remote.compactMap { element in
            tryLog {
                try Network.NW.Peer(local: local, entry: element)
            }
        }

        self.init(result.compactMap { $0 })
    }
}

fileprivate extension Array where Element : Network.NW.PeerBase {
    func removing(_ id: Network.Peer.Identity) -> Array<Element> {
        return filter { !($0.info.id.unique == id.unique) }
    }
}
