//
//  File.swift
//  
//
//  Created by Ivan Kh on 19.04.2023.
//

import Foundation
import Combine
import BlackUtils

extension Network.NW.Connection {
    final class Storage {
        private(set) var items = [Item]()
        private(set) var connections = [Network.NW.Connection]()
        private let subject = KeepValueSubject<[Network.NW.Connection], Never>([])
        private let lock = NSLock()
        var publisher: AnyNewValuePublisher<[Network.NW.Connection], Never> { subject.eraseToAnyNewValuePublisher() }
    }
}

extension Network.NW.Connection.Storage {
    func edit(for connection: Network.NW.Connection, _ block: (inout Item) -> Void) {
        lock.withLock {
            guard let index = items.firstIndex(where: { $0.connection === connection }) else { assertionFailure(); return }
            block(&items[index])
        }
    }

    func add(_ connection: Network.NW.Connection) {
        lock.withLock {
            connections.append(connection)
            items.append(.init(connection: connection))
            subject.send(connections)
        }
    }

    func remove(_ connection: Network.NW.Connection) {
        lock.withLock {
            var item = items.removeFirst { $0.connection === connection }
            _ = connections.removeFirst { $0 === connection }
            item?.cancel()
            subject.send(connections)
        }
    }
    
    func disconnect() async {
        await connections.disconnect()

        lock.withLock {
            for i in 0 ..< items.count {
                items[i].cancel()
            }

            items.removeAll()
            connections.removeAll()
            subject.send(connections)
        }
    }
}

extension Network.NW.Connection.Storage {
    struct Item {
        let connection: Network.NW.Connection
        var dataCancellables = [AnyCancellable]()
        var stateCancellables = [AnyCancellable]()
        var pathCancellables = [AnyCancellable]()
    }
}

extension Network.NW.Connection.Storage.Item {
    mutating func cancel() {
        dataCancellables.cancel()
        stateCancellables.cancel()
        pathCancellables.cancel()

        dataCancellables.removeAll()
        stateCancellables.removeAll()
        pathCancellables.removeAll()
    }
}

extension Network.NW.Connection {
    struct AutoClean {
        private let storage: Storage
        private var cancellables = [(connection: Network.NW.Connection, cancellable: AnyCancellable)]()

        init(storage: Storage) {
            self.storage = storage
        }

        mutating func connection(_ connection: Network.NW.Connection) {
            let storage = storage

            storage.edit(for: connection) { item in
                connection.state
                    .dropFirst()
                    .filter { $0.finished }
                    .sink { state in
                    storage.remove(connection)
                }.store(in: &item.stateCancellables)
            }
        }
    }
}

extension Network.NW.Connection {
    class AutoReconnect {

    }
}

extension Sequence where Element: Network.NW.Connection {
    func disconnect() async {
        await withTaskGroup(of: Void.self) { group in
            self.forEach { connection in
                group.addTask {
                    await connection.stop()
                }
            }
        }
    }
}
