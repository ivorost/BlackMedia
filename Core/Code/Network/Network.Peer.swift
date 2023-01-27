//
//  Network.Peer.swift
//  Core
//
//  Created by Ivan Kh on 20.04.2022.
//

import Foundation
import Combine
import Utils


public extension Network {
    final class Peer {}
}


public protocol PeerProtocol : AnyObject, CustomStringConvertible {
    #if DEBUG
    var debugIdentifier: Int { get }
    var debugDescription: AnyValuePublisher<String, Never> { get }
    #endif

    var id: String { get }
    var name: String { get }
    var state: AnyValuePublisher<Network.Peer.State, Never> { get }
    var get: AnyPublisher<Data, Error> { get }
    
    func connect() async throws -> Bool
    func disconnect() async
    func put(_ data: Data)
}


public extension Network.Peer {
    typealias Proto = PeerProtocol
    typealias PeersPublisher = AnyPublisher<[Proto], Never>
}


public extension Network.Peer {
    // Order better ascending
    enum State : Int {
        case unavailable = 0
        case available
        case disconnected
        case disconnecting
        case connecting
        case connected
    }
}


public extension Network.Peer.State {
    func isGood() -> Bool {
        return self == .available || self == .connected || self == .connecting
    }
    
    func isBad() -> Bool {
        return !isGood()
    }
    
    static func better(_ s1: Network.Peer.State, _ s2: Network.Peer.State) -> Network.Peer.State {
        return s1.rawValue > s2.rawValue
        ? s1
        : s2
    }
}


public extension Array where Element == Network.Peer.Proto {
    func sortedByState() -> Array {
        return sorted { $0.state.value.rawValue > $1.state.value.rawValue }
    }
}


extension Network.Peer {
    open class Proxy {
        #if DEBUG
        public var debugIdentifier: Int { inner.debugIdentifier }
        public var debugDescription: AnyValuePublisher<String, Never> { debugDescriptionSubject.eraseToAnyValuePublisher() }
        private let debugDescriptionSubject = CurrentValueSubject<String, Never>("")
        #endif
        
        private let getSubject = PassthroughSubject<Data, Error>()
        private let stateSubject = CurrentValueSubject<State, Never>(.unavailable)
        private var cancellables = [AnyCancellable]()

        var inner: Proto {
            didSet {
                subscribe(inner)
            }
        }
        
        public init(_ inner: Proto) {
            self.inner = inner
            subscribe(inner)
        }

        private func subscribe(_ peer: Proto) {
            cancellables.cancel()
            peer.get.subscribe(getSubject).store(in: &cancellables)
            peer.state.subscribe(stateSubject).store(in: &cancellables)
            #if DEBUG
            peer.debugDescription.subscribe(debugDescriptionSubject).store(in: &cancellables)
            #endif
        }
    }
}


public extension Network.Peer {
    class StateObservable : Proxy, ObservableObject {
        private var cancellables = [AnyCancellable]()

        override public init(_ inner: Network.Peer.Proto) {
            super.init(inner)
            state
                .receive(on: RunLoop.main)
                .map
                .sink(receiveValue: objectWillChange.send)
                .store(in: &cancellables)
            #if DEBUG
            debugDescription
                .receive(on: RunLoop.main)
                .map
                .sink(receiveValue: objectWillChange.send)
                .store(in: &cancellables)
            #endif
        }
    }
}


extension Network.Peer.Proxy : Network.Peer.Proto {
    public var id: String { return inner.id }
    public var name: String { return inner.name }
    public var state: AnyValuePublisher<Network.Peer.State, Never> { return stateSubject.eraseToAnyValuePublisher() }
    public var get: AnyPublisher<Data, Error> { return getSubject.eraseToAnyPublisher() }
    
    public func connect() async throws -> Bool { return try await inner.connect() }
    public func disconnect() async { await inner.disconnect() }
    public func put(_ data: Data) { inner.put(data) }
}


extension Network.Peer.Proxy : CustomStringConvertible {
    public var description: String {
        return name
    }
}
