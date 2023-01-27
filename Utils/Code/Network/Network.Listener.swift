//
//  Network.Listener.swift
//  Utils-macOS
//
//  Created by Ivan Kh on 23.12.2022.
//

import Network
import Combine

public extension Black.Network {
    final class Listener {
        enum ListenerError : Error {
            case cancelled
        }

        public private(set) var inner: NWListener

        public var state: AnyPublisher<NWListener.State, Never> { stateSubject.eraseToAnyPublisher() }
        public var connection: AnyPublisher<NWConnection, Never> { connectionSubject.eraseToAnyPublisher() }
        private let stateSubject = PassthroughSubject<NWListener.State, Never>()
        private let connectionSubject = PassthroughSubject<NWConnection, Never>()

        public init(_ inner: NWListener) {
            self.inner = inner
        }

        private func _start(on queue: DispatchQueue) {
            inner.stateUpdateHandler = state(changed:)
            inner.newConnectionHandler = inbound(connection:)
            inner.start(queue: queue)
        }
        
        private func _stop() {
            inner.cancel()
        }
                
        private func state(changed to: NWListener.State) {
            self.stateSubject.send(to)
        }
        
        private func inbound(connection: NWConnection) {
            self.connectionSubject.send(connection)
        }
    }
}


extension Black.Network.Listener : Black.Network.SessionProtocol {
    public var queue: DispatchQueue? {
        return inner.queue
    }
    
    public func start(on queue: DispatchQueue = .global()) {
        _start(on: queue)
    }
    
    public func start(on queue: DispatchQueue = .global()) async throws {
        var disposable: AnyCancellable?
        
        try await withCheckedThrowingContinuation { continuation in
            disposable = state.sink { newValue in
                switch newValue {
                case .ready:
                    disposable?.cancel()
                    continuation.resume()
                case .cancelled:
                    disposable?.cancel()
                    continuation.resume(throwing: ListenerError.cancelled)
                case .failed(let error):
                    disposable?.cancel()
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
            
            _start(on: queue)
        }
    }
    
    public func stop() {
        _stop()
    }

    public func stop() async {
        var disposable: AnyCancellable?

        await withCheckedContinuation { continuation in
            disposable = state.sink { newValue in
                switch newValue {
                case .cancelled:
                    disposable?.cancel()
                    continuation.resume()
                case .failed(_):
                    disposable?.cancel()
                    continuation.resume()
                default:
                    break
                }
            }
            
            _stop()
        }
    }
}
