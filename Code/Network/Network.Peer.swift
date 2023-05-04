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

    var info: Network.Peer.Information.AnyProto { get }
    var available: AnyNewValuePublisher<Bool, Never> { get }
    var state: AnyNewValuePublisher<Network.Peer.State, Never> { get }
    var outboundState: AnyNewValuePublisher<Network.Peer.State, Never> { get }
    var get: AnyPublisher<Network.Peer.Data, Error> { get }

    func connect() async throws -> Bool
    func disconnect() async
    func put(_ data: Network.Peer.Data)
}

extension PeerProtocol {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id.unique == rhs.id.unique
    }
}

public extension PeerProtocol {
    var id: Network.Peer.Identity { info.id }
}

public extension Network.Peer {
    typealias Proto = PeerProtocol
    typealias AnyProto = any PeerProtocol
    typealias OptionalPublisher = AnyPublisher<Proto?, Never>
    typealias OptionalValuePublisher = any ValuePublisher<Proto?, Never>
    typealias PeersPublisher = AnyPublisher<[AnyProto], Never>
}

public extension Network.Peer {
    // Order better ascending
    enum State : Int {
        case disconnected = 0
        case disconnecting
        case connecting
        case connected
    }
}

public extension Network.Peer {
    enum Kind : UInt8, Codable {
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
        return self == .connected || self == .connecting
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

public extension Array where Element == Network.Peer.AnyProto {
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
        
        private let availableSubject = KeepValueSubject<Bool, Never>(false)
        private let stateSubject = KeepValueSubject<State, Never>(.disconnected)
        private let outboundStateSubject = KeepValueSubject<State, Never>(.disconnected)
        private let getSubject = PassthroughSubject<Network.Peer.Data, Error>()
        private var cancellables = [AnyCancellable]()

        var inner: AnyProto {
            didSet {
                subscribe(inner)
            }
        }
        
        public init(_ inner: AnyProto) {
            self.inner = inner
            subscribe(inner)
        }

        private func subscribe(_ peer: AnyProto) {
            cancellables.cancel()
            peer.get.subscribe(getSubject).store(in: &cancellables)
            peer.available.subscribe(availableSubject).store(in: &cancellables)
            peer.state.subscribe(stateSubject).store(in: &cancellables)
            peer.outboundState.subscribe(outboundStateSubject).store(in: &cancellables)
            #if DEBUG
            peer.debugDescription.subscribe(debugDescriptionSubject).store(in: &cancellables)
            #endif
        }
    }
}

public extension Network.Peer {
    class StateObservable : Proxy, ObservableObject {
        private var cancellables = [AnyCancellable]()

        override public init(_ inner: AnyProto) {
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
    public var info: Network.Peer.Information.AnyProto {
        return inner.info
    }
    public var available: AnyNewValuePublisher<Bool, Never> {
        availableSubject.eraseToAnyNewValuePublisher()
    }
    public var state: AnyNewValuePublisher<Network.Peer.State, Never> {
        stateSubject.eraseToAnyNewValuePublisher()
    }
    public var outboundState: AnyNewValuePublisher<Network.Peer.State, Never> {
        outboundStateSubject.eraseToAnyNewValuePublisher()
    }
    public var get: AnyPublisher<Network.Peer.Data, Error> {
        getSubject.eraseToAnyPublisher()
    }
    
    public func connect() async throws -> Bool { try await inner.connect() }
    public func disconnect() async { await inner.disconnect() }
    public func put(_ data: Network.Peer.Data) { inner.put(data) }
}

extension Network.Peer.Proxy : CustomStringConvertible {
    public var description: String {
        return id.name
    }
}
