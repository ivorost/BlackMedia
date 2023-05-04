//  Created by Ivan Kh on 26.04.2023.

import Foundation
import Combine
import BlackUtils
#if canImport(UIKit)
import UIKit
#endif

private class ConnectWhenAvailable<Failure: Error>: CustomSubscriberHandler {
    typealias Failure = Failure
    private var peer: Network.Peer.Proto? = nil
    private var cancellable: AnyCancellable?

    func receive(_ peer: Network.Peer.Proto?) {
        cancellable?.cancel()
        guard let peer else { return }

        cancellable = peer.available.removeDuplicates().sink { available in
            print("-------------- AVAILABLE \(available)")

            if available && peer.outboundState.value != .connected {
                Task {
                    await tryLog {
                        try await peer.connect()
                    }
                }
            }
        }
    }
}

private class ConnectWhenEnterForeground<Failure: Error>: CustomSubscriberHandler {
    private var peer: Network.Peer.Proto? = nil
    private var willEnterForegroundNotification: AnyCancellable?

    init() {
        #if canImport(UIKit)
        willEnterForegroundNotification = NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let peer = self?.peer else { return }
                guard peer.outboundState.value != .connected else { return }

                Task {
                    await tryLog {
                        try await peer.connect()
                    }
                }
            }
        #endif
    }

    func receive(_ input: Network.Peer.Proto?) {
        self.peer = input
    }

    func receive(completion: Subscribers.Completion<Failure>) {
        willEnterForegroundNotification?.cancel()
    }
}

public extension Publisher where Output == Network.Peer.AnyProto? {
    func connectWhenAvailable() -> AnyPublisher<Network.Peer.AnyProto?, Failure> {
        CustomSubscriber(upstream: self, handler: ConnectWhenAvailable())
            .eraseToAnyPublisher()
    }
}

public extension Publisher where Output == Network.Peer.AnyProto? {
    func connectWhenEnterForeground() -> AnyPublisher<Network.Peer.AnyProto?, Failure> {
        CustomSubscriber(upstream: self, handler: ConnectWhenEnterForeground())
            .eraseToAnyPublisher()
    }
}
