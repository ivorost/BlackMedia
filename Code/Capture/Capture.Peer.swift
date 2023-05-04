//
//  File.swift
//  
//
//  Created by Ivan Kh on 03.05.2023.
//

import Foundation
import Combine

public extension Capture {
    class Peer: ProducerProtocol & ProcessorProtocol {
        public var next: Data.Processor.AnyProto?
        private let peer: Network.Peer.OptionalValuePublisher
        private var peerDisposable: AnyCancellable?
        private var dataDisposable: AnyCancellable?

        public init(_ peer: Network.Peer.OptionalValuePublisher) {
            self.peer = peer
        }

        private func peer(changed peer: Network.Peer.AnyProto?) {
            dataDisposable?.cancel()
            dataDisposable = peer?.get.sink(receiveCompletion: {_ in }, receiveValue: peer(get:))
        }

        private func peer(get data: Network.Peer.Data) {
            if case let .data(data) = data {
                next?.process(data)
            }
        }

        public func process(_ data: Data) {
            peer.value?.put(.data(data))
        }
    }
}

extension Capture.Peer : Session.Proto {
    public func start() throws {
        peerDisposable = peer.sink(receiveValue: peer(changed:))
        peer(changed: peer.value)
    }

    public func stop() {
        peerDisposable?.cancel()
        dataDisposable?.cancel()

        peerDisposable = nil
        dataDisposable = nil
    }
}
