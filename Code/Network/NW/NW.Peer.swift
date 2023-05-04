//
//  NW.Peer.swift
//  Core-macOS
//
//  Created by Ivan Kh on 27.05.2022.
//

import Foundation
import Network
import Combine
import BlackUtils


public extension Network {
    final class NW {}
}

private extension Network.NW.PeerBase {
    enum Error: Swift.Error {
        case missedService(NWBrowser.Result)
        case missedMetadata(NWBrowser.Result)
    }
}

public extension Network.NW {
    class PeerBase {
        #if DEBUG
        static var debugIdentifier = 0
        public let debugIdentifier: Int
        public var debugDescription: AnyValuePublisher<String, Never> { debug.description }
        private let debug: Debug
        var debugKind: String { "temporary" }
        func debugLog(_ string: String) { print("Peer \(debugIdentifier) to \(info.id.name) (\(debugKind)): \(string)") }
        #else
        @inlinable func debugLog(_ string: String) { }
        #endif

        public var info: Network.Peer.Information.AnyProto

        public var available: AnyNewValuePublisher<Bool, Never> {
            subject.available.eraseToAnyNewValuePublisher()
        }
        public var state: AnyNewValuePublisher<Network.Peer.State, Never> {
            subject.state.eraseToAnyNewValuePublisher()
        }
        public var outboundState: AnyNewValuePublisher<Network.Peer.State, Never> {
            subject.outboundState.eraseToAnyNewValuePublisher()
        }
        public var get: AnyPublisher<Network.Peer.Data, Swift.Error> {
            subject.data.eraseToAnyPublisher()
        }

        fileprivate let subject: Network.NW.Peer.Subject
        fileprivate let localInfo: Network.Peer.Information.AnyProto
        fileprivate let storage = Network.NW.Peer.Storage()

        fileprivate let subscriber: Network.NW.Peer.Subscriber
        private var inboundAutoClean: Connection.AutoClean
        fileprivate var outboundAutoClean: Connection.AutoClean

        init(local: Network.Peer.Information.AnyProto, remote: Network.Peer.Information.AnyProto) {
            self.localInfo = local
            self.info = remote

            let subject = Network.NW.Peer.Subject(storage: storage)
            var subscriber = Network.NW.Peer.Subscriber(subject: subject, storage: storage)

            self.subject = subject
            self.inboundAutoClean = Connection.AutoClean(storage: storage.inbound)
            self.outboundAutoClean = Connection.AutoClean(storage: storage.outbound)

            #if DEBUG
            PeerBase.debugIdentifier += 1
            debugIdentifier = PeerBase.debugIdentifier
            debug = Debug(storage: storage, debugIdentifier: debugIdentifier)
            subscriber.debug = debug
            #endif

            self.subscriber = subscriber

            #if DEBUG
            if remote.id.unique != local.id.unique { debugLog("init") }
            #endif
        }

        public func add(inbound connection: Connection) {
            debugLog("set inbound (\(connection.debugIdentifier) \(connection.state.value.string)")
            storage.inbound(connection: connection)
            subscriber.inbound(connection)
            inboundAutoClean.connection(connection)
        }

        public func set(available: Bool) {
            subject.available.send(available)
        }

        public func setInbound(from peer: PeerBase) {
            for connection in peer.storage.inbound.connections {
                add(inbound: connection)
            }
        }

        public func put(_ data: Network.Peer.Data) {
            storage.connections.best?.send(data)
        }

        public func disconnect() async {
            await storage.disconnect()
        }
    }
}

extension Network.NW.PeerBase : CustomStringConvertible {
    public var description: String {
        return info.id.name
    }
}

public extension Network.NW {
    class Peer : PeerBase, Network.Peer.Proto {
        #if DEBUG
        override var debugKind: String { "discovered" }
        #endif

        fileprivate let entry: NWBrowser.Result

        init?(local info: Network.Peer.Information.AnyProto, entry: NWBrowser.Result) throws {
            guard case let .service(name, _, _, _) = entry.endpoint
            else { throw Error.missedService(entry) }

            guard case let .bonjour(txtRecord) = entry.metadata
            else { throw Error.missedMetadata(entry) }

            let identity = try Network.Peer.Identity(unique: name, dictionary: txtRecord.dictionary)

            self.entry = entry

            super.init(local: info,
                       remote: Network.Peer.Information.Basic(identity, dictionary: txtRecord.dictionary))
        }

        public func connect() async throws -> Bool {
            let bestState = storage.outbound.connections.best?.state.value
            guard bestState != .ready && bestState != .preparing else { return false }
            let connection = OutboundConnection(endpoint: entry.endpoint, information: localInfo, passcode: "")

            debugLog("connect.prepare to \(id.name)")
            storage.outbound(connection: connection)
            subscriber.outbound(connection)
            outboundAutoClean.connection(connection)
            try await connect(to: connection)
            debugLog("connect.done (\(connection.state.value.string))")

            return true
        }


        private func connect(to connection: OutboundConnection) async throws {
            let state = state

            // here we wait for first connection established
            try await withCheckedThrowingContinuation { continuation in
                Task {
                    do {
                        try await withThrowingTaskGroup(of: Void.self) { group in
                            group.addTask {
                                var stateCancellable: AnyCancellable?


                                await withCheckedContinuation { continuation in
                                    let cancel = {
                                        stateCancellable?.cancel()
                                        stateCancellable = nil
                                        continuation.resume()
                                    }

                                    stateCancellable = state.sink { state in
                                        if state == .connected, stateCancellable != nil {
                                            cancel()
                                        }
                                    }

                                    if state.value == .connected, stateCancellable != nil {
                                        cancel()
                                    }
                                }
                            }

                            group.addTask {
                                try await connection.start()
                            }

                            debugLog("connect.start")
                            try await group.next()
                            debugLog("connect.first finished")
                            continuation.resume()
                            debugLog("connect.resume")
                            try? await group.reduce(()) { _, _ in () }
                            debugLog("connect.all tasks finished")
                        }
                    }
                    catch {
                        debugLog("connect.error \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}


extension Network.NW {
    class InboundPeer : PeerBase, Network.Peer.Proto {
        public func connect() async throws -> Bool {
            return false
        }
    }
}

