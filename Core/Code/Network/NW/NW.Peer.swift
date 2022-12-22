//
//  NW.Peer.swift
//  Core-macOS
//
//  Created by Ivan Kh on 27.05.2022.
//

import UIKit
import Network
import Combine


public extension Network {
    final class NW {}
}


public extension Network.NW {
    class PeerBase {
        #if DEBUG
        static var debugIdentifier = 0
        public let debugIdentifier: Int
        var debugKind: String { "temporary" }
        func debugLog(_ string: String) { print("Peer \(debugIdentifier) to \(endpointName.name) (\(debugKind)): \(string)") }
        #endif
        
        let endpointName: EndpointName
        
        public var id: String {
            return endpointName.encoded
        }
        
        public var pin: String {
            return endpointName.pin
        }
        
        public var name: String {
            return endpointName.name
        }
        
        public var state: Network.Peer.State {
            return .init(inboundConnection)
        }
        
        public var get: AnyPublisher<Data, Never> { dataSubject.eraseToAnyPublisher() }
        fileprivate let dataSubject = PassthroughSubject<Data, Never>()
        fileprivate private(set) var inboundConnection: Connection?
        private var inboundDataDisposable: AnyCancellable?

        fileprivate init(_ endpointName: EndpointName) {
            self.endpointName = endpointName
            
            #if DEBUG
            PeerBase.debugIdentifier += 1
            debugIdentifier = PeerBase.debugIdentifier
            debugLog("init")
            #endif
        }
        
        public func set(inbound connection: Connection) async -> Bool {
            if inboundConnection?.state == .ready {
                return false
            }

            #if DEBUG
            debugLog("set1 inbound (\(connection.debugIdentifier) \(String(describing: connection.state))")
            #endif

            inboundDataDisposable?.cancel()
            await inboundConnection?.stop()

            inboundDataDisposable = connection.$data.subscribe(dataSubject)
            set(inbound: connection) as Void
            
            return true
        }
        
        fileprivate func set(inbound connection: Connection) {
            assert(inboundConnection == nil)
            inboundConnection = connection
            #if DEBUG
            debugLog("set2 inbound (\(connection.debugIdentifier) \(String(describing: connection.state))")
            #endif
        }
        
        public func disconnect() async {
            await inboundConnection?.stop()
        }
    }
}

public extension Network.NW {
    class Peer : PeerBase, Network.Peer.Proto {
        #if DEBUG
        override var debugKind: String { "discovered" }
        #endif

        fileprivate let nwEndpoint: NWEndpoint
        private var outboundConnection: OutboundConnection?
        private var outboundDataDisposable: AnyCancellable?

        private var connection: Connection? {
            return outboundConnection != nil
            ? outboundConnection
            : inboundConnection
        }
        
        public override var state: Network.Peer.State {
            return .better(super.state, .init(outboundConnection))
        }
        
        init?(_ nw: NWEndpoint) {
            if case let .hostPort(host, port) = nw {
                print("hostport: \(host) \(port)")
                return nil
            }

            guard case let .service(name, _, _, _) = nw
            else {
                assertionFailure()
                return nil
            }
            
            self.nwEndpoint = nw
            super.init(EndpointName.decode(name))
        }
        
        public func connect() async throws -> Bool {
            guard let endpointNameData = EndpointName.currentData else { return false }
            
            assert(outboundConnection == nil)
            
            #if DEBUG
            debugLog("connecting")
            #endif
            
            outboundDataDisposable?.cancel()
            await outboundConnection?.stop()
            
            outboundConnection = OutboundConnection(endpoint: nwEndpoint,
                                                    identifier: endpointNameData,
                                                    passcode: "")

            outboundDataDisposable = outboundConnection?.$data.subscribe(dataSubject)
            try await outboundConnection?.start()
            #if DEBUG
            debugLog("send id \(EndpointName.current.pin) \(EndpointName.current.name)")
            #endif
            try await outboundConnection?.send(endpointNameData)

            #if DEBUG
            debugLog("connected (\(outboundConnection?.debugIdentifier ?? 0) \(String(describing: outboundConnection?.state))")
            #endif

            return true
        }
        
        public override func disconnect() async {
            await super.disconnect()
            await outboundConnection?.stop()
        }
        
        public func put(_ data: Data) {
            connection?.send(data)
        }
    }
}


public extension Network.NW {
    class InboundPeer : PeerBase, Network.Peer.Proto {

        public func connect() async throws -> Bool {
            assertionFailure()
            return false
        }
        
        public func put(_ data: Data) {
            inboundConnection?.send(data)
        }
    }
}


extension Network.NW.Peer : CustomStringConvertible {
    public var description: String {
        return name
    }
}


extension Array where Element == Network.NW.Peer {
    init<S: Sequence>(_ nw: S) where S.Element == NWBrowser.Result {
        self.init(nw.compactMap { Network.NW.Peer($0.endpoint) })
    }
}

extension Array where Element : Network.NW.PeerBase {
    func first(_ endpointName: Network.NW.EndpointName) -> Element? {
        return first { $0.endpointName == endpointName }
    }
    
    func removing(enpoint endpointName: Network.NW.EndpointName) -> Array<Element> {
        return filter { $0.endpointName != endpointName }
    }
}


public extension Network.NW {
    class PeerStore : ObservableObject {
        @Published public private(set) var peers = [Network.Peer.Proto]()
        private var foundPeers = [Peer]()
        private var inboundPeers = [InboundPeer]()

        func received(connection: Connection, for endpointName: EndpointName) async {
            await peer(endpointName) { peer in
                if await peer.set(inbound: connection) != true {
                    await connection.stop()
                }
            }
        }
        
        func received(peers: [Peer]) {
            var peersCopy = peers
            
            for peer in peers {
                guard foundPeers.first(peer.endpointName) == nil else { continue }
                
                if let inboundPeer = inboundPeers.first(peer.endpointName) {
                    if let inboundConnection = inboundPeer.inboundConnection {
                        peer.set(inbound: inboundConnection)
                    }
                    
                    _ = inboundPeers.removeFirst { $0 === inboundPeer }
                }
                
                foundPeers.append(peer)
                peersCopy.append(peer)
            }
            
            self.peers = peers
        }

        private func peer(_ endpointName: EndpointName, action: (PeerBase) async -> Void) async {
            if let peer = foundPeers.first(endpointName) {
                await action(peer)
                return
            }

            if let peer = inboundPeers.first(endpointName) {
                await action(peer)
                return
            }
            
            // add inbound peer if can't find existing
            
            let peer = InboundPeer(endpointName)
            var peers = self.peers

            await action(peer)
            inboundPeers.append(peer)
            peers.append(peer)
            self.peers = peers
        }
    }
}
