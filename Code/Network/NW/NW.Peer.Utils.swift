
import Foundation
import Combine
import Network
import BlackUtils


public extension Sequence where Element == Network.Peer.Proto {
    var hasConnected: Bool {
        firstConnected != nil
    }

    var firstConnected: Element? {
        first { $0.state.value == .connected }
    }

    func connectReturningFirst() async throws -> Element? {
        await withTaskGroupContinuation(of: Element.self) { continuation, group in
            for peer in self {
                group.addTask {
                    await tryLog { _ = try await peer.connect() }
                    return peer
                }
            }

            let connectedPeer = await group.first { $0.state.value == .connected }
            continuation.resume(returning: connectedPeer)
        }
    }

    func disconnect() async {
        await withTaskGroup(of: Void.self) { group in
            for i in self {
                group.addTask {
                    await i.disconnect()
                }
            }
        }
    }

    func contains(_ peer: Element) -> Bool {
        contains { $0.info.id.unique == peer.id.unique }
    }
}

public extension Sequence where Element: Network.Peer.Proto {
    func contains(_ peer: Element) -> Bool {
        first(peer.id) != nil
    }

    func first(_ id: Network.Peer.Identity) -> Element? {
        return first { $0.info.id.unique == id.unique }
    }
}

extension Network.NW.Peer {
    class Storage {
        private(set) var inbound = Network.NW.Connection.Storage()
        let outbound = Network.NW.Connection.Storage()
        var publisher: AnyNewValuePublisher<[Network.NW.Connection], Never> { subject.eraseToAnyNewValuePublisher() }
        private let subject = KeepValueSubject<[Network.NW.Connection], Never>([])
        private var subscriptions = [AnyCancellable]()

        init() {
            let inbound = inbound
            let outbound = outbound

            inbound.publisher
                .map { outbound.connections + $0 }
                .subscribe(subject)
                .store(in: &subscriptions)

            outbound.publisher
                .map { $0 + inbound.connections }
                .subscribe(subject)
                .store(in: &subscriptions)
        }

        var connections: [Network.NW.Connection] {
            outbound.connections + inbound.connections
        }

        func inbound(connection: Network.NW.Connection) {
            inbound.add(connection)
        }

        func outbound(connection: Network.NW.Connection) {
            outbound.add(connection)
        }

        func disconnect() async {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.inbound.disconnect() }
                group.addTask { await self.outbound.disconnect() }
            }
        }
    }
}

extension Network.NW.Peer {
    class Subject {
        var available = KeepValueSubject<Bool, Never>(false)
        let state = KeepValueSubject<Network.Peer.State, Never>(.disconnected)
        let outboundState = KeepValueSubject<Network.Peer.State, Never>(.disconnected)
        let data = PassthroughSubject<Network.Peer.Data, Swift.Error>()
        private let storage: Storage

        init(storage: Storage) {
            self.storage = storage
        }

        func updateState() {
            let newState = Network.Peer.State(storage.connections.best)
            let newOutboundState = Network.Peer.State(storage.outbound.connections.best)

            if newState != state.value {
                state.send(newState)
            }

            if newOutboundState != outboundState.value {
                outboundState.send(newOutboundState)
            }
        }
    }
}

extension Network.NW.Peer {
    struct Subscriber {
        private let subject: Subject
        private let storage: Network.NW.Peer.Storage
        private let outboundSatateSubscription: AnyCancellable
        #if DEBUG
        var debug: Network.NW.PeerBase.Debug?
        #endif

        init(subject: Subject, storage: Network.NW.Peer.Storage) {
            self.subject = subject
            self.storage = storage

            outboundSatateSubscription = storage.outbound.publisher.sink { connections in
                subject.updateState()
            }
        }

        func inbound(_ connection: Network.NW.Connection) {
            received(connection: connection, in: storage.inbound)
        }

        func outbound(_ connection: Network.NW.Connection) {
            received(connection: connection, in: storage.outbound)
        }

        private func received(connection: Network.NW.Connection, in storage: Network.NW.Connection.Storage) {
            let subject = subject

            storage.edit(for: connection) { item in
                connection.state.sink { value in
                    subject.updateState()
                    #if DEBUG
                    debug?.update()
                    #endif
                }.store(in: &item.stateCancellables)

                connection.inner.path.sink { path in
                    #if DEBUG
                    debug?.update()
                    #endif
                }.store(in: &item.pathCancellables)

                connection.data
                    .subscribe(subject.data)
                    .store(in: &item.dataCancellables)
            }

            subject.updateState()
        }
    }
}

#if DEBUG
extension Network.NW.PeerBase {
    class Debug {
        let storage: Network.NW.Peer.Storage
        let debugIdentifier: Int
        var description: AnyValuePublisher<String, Never> { descriptionSubject.eraseToAnyValuePublisher() }
        private let descriptionSubject = CurrentValueSubject<String, Never>("")
        private var storageSubscription: AnyCancellable?

        init(storage: Network.NW.Peer.Storage, debugIdentifier: Int) {
            self.storage = storage
            self.debugIdentifier = debugIdentifier

            storageSubscription = storage.publisher.sink { [weak self] _ in
                self?.update()
            }

            update()
        }

        func update() {
            var inboundDescription = Network.NW.Connection.debugDescription(storage.inbound.connections.best,
                                                                            kind: "inbound")
            var outboundDescription = Network.NW.Connection.debugDescription(storage.outbound.connections.best,
                                                                             kind: "outbound")

            inboundDescription += " (\(storage.inbound.connections.count))"
            outboundDescription += " (\(storage.outbound.connections.count))"

            descriptionSubject.send("Peer \(debugIdentifier)\n\(inboundDescription)\n\(outboundDescription)")
        }
    }
}
#endif

fileprivate extension Network.Peer.State {
    init(_ state: NWConnection.State) {
        switch state {
        case .ready: self = .connected
        case .setup: self = .connecting
        case .preparing: self = .connecting
        case .waiting(_): self = .connecting
        case .cancelled: self = .disconnected
        case .failed(_): self = .disconnected
        @unknown default: self = .disconnected
        }
    }

    init(_ connection: Network.NW.Connection?) {
        guard connection != nil else { self = .disconnected; return }
        guard let state = connection?.state.newValue else { self = .disconnected; return }
        self = .init(state)
    }
}

extension Sequence where Element == Network.NW.Connection {
    var best: Network.NW.Connection? {
        self.sorted {
            Network.Peer.State($0.state.newValue).rawValue > Network.Peer.State($1.state.newValue).rawValue
        }
        .first
    }
}
