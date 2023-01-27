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
        fileprivate struct ConnectionInfo {
            var connection: Connection?
            var dataDisposable: AnyCancellable?
            var stateDisposable: AnyCancellable?
        }
        
        #if DEBUG
        static var debugIdentifier = 0
        public let debugIdentifier: Int
        public var debugDescription: AnyValuePublisher<String, Never> { debugDescriptionSubject.eraseToAnyValuePublisher() }
        fileprivate let debugDescriptionSubject = CurrentValueSubject<String, Never>("")
        var debugKind: String { "temporary" }
        func debugLog(_ string: String) { print("Peer \(debugIdentifier) to \(endpointName.name) (\(debugKind)): \(string)") }
        fileprivate func updateDebugDescription() {
            let inboundDescription = Connection.debugDescription(inbound.connection, kind: "inbound")
            debugDescriptionSubject.send("Peer \(debugIdentifier)\n\(inboundDescription)")
        }
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
        
        public var get: AnyPublisher<Data, Error> { dataSubject.eraseToAnyPublisher() }
        public var state: AnyValuePublisher<Network.Peer.State, Never> { stateSubject.eraseToAnyValuePublisher() }
        fileprivate let dataSubject = PassthroughSubject<Data, Error>()
        fileprivate let stateSubject = CurrentValueSubject<Network.Peer.State, Never>(.unavailable)
        fileprivate var inbound = ConnectionInfo() {
            didSet {
                #if DEBUG
                updateDebugDescription()
                #endif
            }
        }

        fileprivate init(_ endpointName: EndpointName) {
            self.endpointName = endpointName
            
            #if DEBUG
            PeerBase.debugIdentifier += 1
            debugIdentifier = PeerBase.debugIdentifier
            if endpointName != EndpointName.current { debugLog("init") }
            debugDescriptionSubject.send("Peer \(debugIdentifier)")
            #endif
        }

        @discardableResult public func set(inbound connection: Connection) async -> Bool {
            inbound = await setup(connection: connection, to: inbound)

            #if DEBUG
            debugLog("set inbound (\(connection.debugIdentifier) \(connection.state.value.string)")
            #endif
            
            return true
        }
        
        fileprivate func setup(connection: Connection?, to dst: ConnectionInfo) async -> ConnectionInfo {
            if dst.connection?.state.value == .ready || dst.connection?.reconnecting == true {
                return dst
            }

            dst.stateDisposable?.cancel()
            dst.dataDisposable?.cancel()
            await dst.connection?.stop()

            if let connection {
                #if DEBUG
                debugLog("setup connection (\(connection.debugIdentifier) \(connection.state.value.string))")
                #endif

                var result = ConnectionInfo()
                result.connection = connection
                result.dataDisposable = connection.data.subscribe(dataSubject)
                result.stateDisposable = connection.state.sink(receiveValue: state(changed:))
                return result
            }
            else {
                return ConnectionInfo()
            }
        }
        
        final fileprivate func state(changed to: NWConnection.State) {
            Task { await updateConnection() }
            updateState()
        }

        fileprivate func updateConnection() async {
            if inbound.connection?.isFinished == true {
                inbound = await setup(connection: nil, to: inbound)
            }
        }

        fileprivate func updateState() {
            #if DEBUG
            updateDebugDescription()
            #endif

            let newState = Network.Peer.State(inbound.connection)
            guard state.value != newState else { return }

            #if DEBUG
            debugLog("state: \(newState)")
            #endif
            stateSubject.send(newState)
        }

        fileprivate func disconnect(_ info: inout ConnectionInfo) async {
            info.dataDisposable?.cancel()
            info.dataDisposable = nil
            await info.connection?.stop()
            info.stateDisposable?.cancel()
            info.stateDisposable = nil
        }
        
        public func disconnect() async {
            await disconnect(&inbound)
        }
    }
}

extension Network.NW.PeerBase : CustomStringConvertible {
    public var description: String {
        return name
    }
}

public extension Network.NW {
    class Peer : PeerBase, Network.Peer.Proto {
        #if DEBUG
        override var debugKind: String { "discovered" }
        override func updateDebugDescription() {
            let inboundDescription = Connection.debugDescription(inbound.connection, kind: "inbound")
            let outboundDescription = Connection.debugDescription(outbound.connection, kind: "outbound")
            debugDescriptionSubject.send("Peer \(debugIdentifier)\n\(inboundDescription)\n\(outboundDescription)")
        }
        #endif

        fileprivate let nwEndpoint: NWEndpoint
        private var outbound = ConnectionInfo() {
            didSet {
                #if DEBUG
                updateDebugDescription()
                #endif
            }
        }

        private var readyConnection: Connection? {
            if outbound.connection?.state.value == .ready {
                return outbound.connection
            }
            
            if inbound.connection?.state.value == .ready {
                return inbound.connection
            }
            
            return nil
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
            guard outbound.connection?.state.value != .ready else { return false }

            #if DEBUG
            debugLog("connecting")
            #endif
            
            let connection = OutboundConnection(endpoint: nwEndpoint,
                                                identifier: endpointNameData,
                                                passcode: "")
            
            outbound = await setup(connection: connection, to: outbound)
            try await connection.start()
            
            #if DEBUG
            debugLog("send id \(EndpointName.current.pin) \(EndpointName.current.name)")
            #endif
            
            try await connection.sendAsync(endpointNameData)

            #if DEBUG
            debugLog("connected (\(connection.debugIdentifier) \(connection.state.value.string))")
            #endif

            return true
        }
        
        public override func disconnect() async {
            await super.disconnect()
            await disconnect(&outbound)
        }
        
        public func put(_ data: Data) {
            readyConnection?.send(data)
        }

        override func updateState() {
            #if DEBUG
            updateDebugDescription()
            #endif

            let inboundState = Network.Peer.State(inbound.connection)
            let outboundState = Network.Peer.State(outbound.connection)
            let newState = Network.Peer.State.better(inboundState, outboundState)
            guard state.value != newState else { return }

            #if DEBUG
            debugLog("state: \(newState)")
            #endif

            stateSubject.send(newState)
        }

        override func updateConnection() async {
            await super.updateConnection()

            if outbound.connection?.isFinished == true {
                outbound = await setup(connection: nil, to: outbound)
            }
        }
    }
}


public extension Network.NW {
    class InboundPeer : PeerBase, Network.Peer.Proto {

        public func connect() async throws -> Bool {
            return false
        }
        
        public func put(_ data: Data) {
            inbound.connection?.send(data)
        }
    }
}


extension Array where Element == Network.NW.Peer {
    init<S: Sequence>(_ nw: S) where S.Element == NWBrowser.Result {
        self.init(nw.compactMap { Network.NW.Peer($0.endpoint) })
    }
}


fileprivate extension Array where Element : Network.Peer.Proxy {
    func first(_ endpointName: Network.NW.EndpointName) -> Element? {
        return first { ($0.inner as? Network.NW.PeerBase)?.endpointName == endpointName }
    }
}


extension Array where Element : Network.NW.PeerBase {
    func removing(enpoint endpointName: Network.NW.EndpointName) -> Array<Element> {
        return filter { $0.endpointName != endpointName }
    }
}


public extension Network.NW {
    class PeerStore : ObservableObject {
        public  var peers: AnyPublisher<[Network.Peer.Proto], Never> { peersSubject.eraseToAnyPublisher() }
        private let peersSubject = PassthroughSubject<[Network.Peer.Proto], Never>()
        private var allPeers = [Network.Peer.Proxy]()

        func received(connection: Connection, for endpointName: EndpointName) async {
            await peer(endpointName) { peer in
                if await peer.set(inbound: connection) != true {
                    await connection.stop()
                }
            }
        }
        
        func received(peers: [Peer]) async {
            var allPeers = allPeers
            
            for peer in peers {
                guard let existingPeer = allPeers.first(peer.endpointName) else {
                    allPeers.append(.init(peer))
                    continue
                }
                
                if let inboundPeer = existingPeer.inner as? InboundPeer {
                    if let inboundConnection = inboundPeer.inbound.connection {
                        await peer.set(inbound: inboundConnection)
                    }
                    
                    existingPeer.inner = peer
                }
            }
            
            set(peers: allPeers)
            print("PeerStore: received \(allPeers)")
        }

        private func peer(_ endpointName: EndpointName, action: (PeerBase) async -> Void) async {
            if let peer = allPeers.first(endpointName)?.inner as? PeerBase {
                await action(peer)
                return
            }
            
            // add inbound peer if can't find existing
            
            let peer = InboundPeer(endpointName)
            var allPeers = allPeers

            await action(peer)
            allPeers.append(.init(peer))
            set(peers: allPeers)
            print("PeerStore: added temporary \(peers)")
        }
        
        private func set(peers: [Network.Peer.Proxy]) {
            allPeers = peers
            peersSubject.send(peers)
        }
    }
}
