//
//  Network.Peer.swift
//  Core
//
//  Created by Ivan Kh on 20.04.2022.
//

#if canImport(UIKit)
import UIKit
#endif
import Foundation
import Combine
import BlackUtils

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
    var kind: Network.Peer.Kind { get }
    var state: AnyValuePublisher<Network.Peer.State, Never> { get }
    var get: AnyPublisher<Network.Peer.Data, Error> { get }
    
    func connect() async throws -> Bool
    func disconnect() async
    func put(_ data: Network.Peer.Data)
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


public extension Network.Peer {
    enum Kind : UInt64, Codable {
        case unknown = 0
        case iPhone
        case iPad
        case Mac
    }
}

extension Network.Peer.Kind {
#if canImport(UIKit)
    static let current: Network.Peer.Kind = UIDevice.current.userInterfaceIdiom == .pad
    ? .iPad
    : UIDevice.current.userInterfaceIdiom == .mac ? .Mac
    : .iPhone
#else
    static let current: Network.Peer.Kind = .Mac
#endif
}

public extension Network.Peer {
    enum Data {
        case data(Foundation.Data)
        case pair
        case skip
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
        
        private let getSubject = PassthroughSubject<Network.Peer.Data, Error>()
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
    public var kind: Network.Peer.Kind { return inner.kind }
    public var state: AnyValuePublisher<Network.Peer.State, Never> { return stateSubject.eraseToAnyValuePublisher() }
    public var get: AnyPublisher<Network.Peer.Data, Error> { return getSubject.eraseToAnyPublisher() }
    
    public func connect() async throws -> Bool { return try await inner.connect() }
    public func disconnect() async { await inner.disconnect() }
    public func put(_ data: Network.Peer.Data) { inner.put(data) }
}


extension Network.Peer.Proxy : CustomStringConvertible {
    public var description: String {
        return name
    }
}


extension Network.Peer {
    open class Generic : Proto {
        #if DEBUG
        public var debugIdentifier: Int = 0
        public var debugDescription: AnyValuePublisher<String, Never> { debugDescriptionSubject.eraseToAnyValuePublisher() }
        public var debugDescriptionSubject = CurrentValueSubject<String, Never>("")
        #endif

        public let getSubject = PassthroughSubject<Data, Error>()
        public let stateSubject = CurrentValueSubject<State, Never>(.unavailable)

        public var id: String = ""
        public var name: String = ""
        public var kind: Network.Peer.Kind = .unknown
        public var state: AnyValuePublisher<Network.Peer.State, Never> { stateSubject.eraseToAnyValuePublisher() }
        public var get: AnyPublisher<Data, Error> { getSubject.eraseToAnyPublisher() }

        public func connect() async throws -> Bool { return false }
        public func disconnect() async {}
        public func put(_ data: Data) {}

        public init() {}
        public init(id: String, name: String, kind: Kind, state: State) {
            self.id = id
            self.name = name
            self.kind = kind
            self.stateSubject.send(state)
        }

        public var description: String {
            return name
        }
    }
}
