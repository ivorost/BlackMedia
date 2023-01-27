//
//  Browser.swift
//  Utils-macOS
//
//  Created by Ivan Kh on 23.12.2022.
//

import Network
import Combine

public extension Black.Network {
    final class Browser {
        public struct Update {
            public let peers: Set<NWBrowser.Result>
            public let changes: Set<NWBrowser.Result.Change>
        }
        
        enum BrowserError : Error {
            case cancelled
        }

        public private(set) var inner: NWBrowser

        public var state: AnyPublisher<NWBrowser.State, Never> { stateSubject.eraseToAnyPublisher() }
        public var update: AnyPublisher<Update, Never> { updateSubject.eraseToAnyPublisher() }
        private let stateSubject = PassthroughSubject<NWBrowser.State, Never>()
        private let updateSubject = PassthroughSubject<Update, Never>()

        public init(_ inner: NWBrowser) {
            self.inner = inner
        }

        private func _start(on queue: DispatchQueue) {
            inner.stateUpdateHandler = state(changed:)
            inner.browseResultsChangedHandler = update(changed:changes:)
            inner.start(queue: queue)
        }


        private func _stop() {
            inner.cancel()
        }
                
        private func state(changed to: NWBrowser.State) {
            self.stateSubject.send(to)
        }
        
        private func update(changed to: Set<NWBrowser.Result>, changes: Set<NWBrowser.Result.Change>) {
            self.updateSubject.send(Update(peers: to, changes: changes))
        }
    }
}


extension Black.Network.Browser : Black.Network.SessionProtocol {
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
                    continuation.resume(throwing: BrowserError.cancelled)
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
