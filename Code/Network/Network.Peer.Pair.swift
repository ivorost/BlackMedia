//
//  Network.Peer.Pair.swift
//  Core
//
//  Created by Ivan Kh on 15.03.2023.
//

import Foundation
import Combine
import BlackUtils

public protocol NetworkPeerPairProtocol {
    var remote: Network.Peer.Proto { get }
    var state: AnyValuePublisher<Network.Peer.Pair.State, Never> { get }
    func pair()
    func skip()
}

public extension Network.Peer {
    final class Pair {}
}

public extension Network.Peer.Pair {
    typealias Proto = NetworkPeerPairProtocol
}

public extension Network.Peer.Pair {
    enum State: Codable {
        case undefined
        case accepted
        case paired
        case skipped
    }
}

public extension Network.Peer.Pair {
    class General: Proto {
        public var remote: Network.Peer.Proto
        public var state: AnyValuePublisher<Network.Peer.Pair.State, Never> { stateSubject.eraseToAnyValuePublisher() }
        private var stateSubject = CurrentValueSubject<State, Never>(.undefined)

        public func pair() {
        }

        public func skip() {
        }

        public init(_ remote: Network.Peer.Proto) {
            self.remote = remote
        }
    }
}

public extension Network.Peer.Pair {
    class Remote: Proto {
        public var remote: Network.Peer.Proto
        public var state: AnyValuePublisher<State, Never> { stateSubject.eraseToAnyValuePublisher() }
        private var stateSubject: CurrentValueSubject<State, Never>
        private var pairingRequested = false
        private var dataCancellable: AnyCancellable?

        public init(remote: Network.Peer.Proto, state: CurrentValueSubject<State, Never>) {
            self.remote = remote
            self.stateSubject = state

            dataCancellable = remote.get.sink( receiveCompletion: { _ in }) { [weak self] data in
                if case .pair = data {
                    if state.value == .accepted {
                        self?.stateSubject.send(.paired)
                    }

                    self?.pairingRequested = true
                }

                if case .skip = data {
                    self?.stateSubject.send(.skipped)
                }
            }
        }

        public func pair() {
            if pairingRequested {
                stateSubject.send(.paired)
            }
            else {
                remote.put(.pair)
            }
        }

        public func skip() {
            remote.put(.skip)
        }
    }
}

public extension Network.Peer.Pair {
    class UserDefaults: Proto {
        public var remote: Network.Peer.Proto = Network.Peer.Generic()
        public var state: AnyValuePublisher<State, Never> { stateSubject.eraseToAnyValuePublisher() }
        private var stateSubject: CurrentValueSubject<State, Never>
        private var stateCancellable: AnyCancellable?

        public init(state: CurrentValueSubject<State, Never>) {
            self.stateSubject = state
            read()

            stateCancellable = state.sink { [weak self] state in
                self?.write(state) }
        }

        public func pair() {}
        public func skip() {}

        private func read() {
            do {
                let peers = Foundation.UserDefaults.standard.dictionary(forKey: "peers")
                guard let peerData = peers?[remote.id] as? Data else { return }
                let state = try JSONDecoder().decode(State.self, from: peerData)

                self.stateSubject.send(state)
            }
            catch {
                logError(error)
            }
        }

        private func write(_ state: State) {
            do {
                let peerData = try JSONEncoder().encode(state)
                var peers = Foundation.UserDefaults.standard.dictionary(forKey: "peers")

                if peers == nil {
                    peers = [:]
                }
                
                peers?[remote.id] = peerData
                Foundation.UserDefaults.standard.set(peers, forKey: "peers")
            }
            catch {
                logError(error)
            }
        }
    }
}
