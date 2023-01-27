/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implement a TLS connection that supports the custom GameProtocol framing protocol.
*/

import Foundation
import Network
import Combine


public extension Network.NW {
    class Connection {
        #if DEBUG
        static var debugIdentifier = 0
        let debugIdentifier: Int
        var debugKind: String { return "unknown" }
        func debugLog(_ string: String) { print("Connection \(debugIdentifier): \(string)") }
        #endif
        
        public var state: AnyNewValuePublisher<NWConnection.State, Never> { stateSubject.eraseToAnyNewValuePublisher() }
        fileprivate let stateSubject = NewValueSubject<NWConnection.State, Never>(.setup)

        public var data: AnyPublisher<Data, Error> { dataSubject.eraseToAnyPublisher() }
        private let dataSubject = PassthroughSubject<Data, Error>()

        let inner: Black.Network.Connection
        var isFinished: Bool { inner.isFinished }
        private var cancellables = [AnyCancellable]()

        fileprivate init(connection: NWConnection) {
            #if DEBUG
            Connection.debugIdentifier += 1
            debugIdentifier = Connection.debugIdentifier
            #endif

            self.inner = .init(connection: connection)

            inner.state
                .sink(receiveValue: { [weak self] state in self?.state(changed: state) })
                .store(in: &cancellables)
            inner.data.map { $0.data }
                .subscribe(dataSubject)
                .store(in: &cancellables)

            #if DEBUG
            debugLog("init \(debugKind)")
            #endif
        }

        deinit {
            #if DEBUG
            debugLog("deinit")
            #endif
        }
        
        var reconnecting: Bool {
            if case .waiting(_) = state.value {
                return state.newValue == .ready
            }
            else {
                return false
            }
        }
        
        fileprivate func start() async throws {
            #if DEBUG
            debugLog("starting")
            #endif

            try await inner.start()

            #if DEBUG
            debugLog("started")
            #endif
        }

        func stop() async {
            #if DEBUG
            debugLog("stopping")
            #endif

            await inner.stop()

            #if DEBUG
            debugLog("stoped")
            #endif
        }

        func sendAsync(_ data: Data, of type: BlackProtocol.MessageType = .data) async throws {
            let message = NWProtocolFramer.Message(type)
            let context = NWConnection.ContentContext(identifier: "black", metadata: [message])

            try await inner.sendAsync(data, in: context)

            #if DEBUG
//            debugLog("send data of size \(data.count) (\(String(describing: state)))")
            #endif
        }
        
        func send(_ data: Data, of type: BlackProtocol.MessageType = .data) {
            let message = NWProtocolFramer.Message(type)
            let context = NWConnection.ContentContext(identifier: "black", metadata: [message])

            inner.send(data, in: context)
        }
        
        func read(_ type: BlackProtocol.MessageType = .data) async throws -> Data {
            repeat {
                let result = try await inner.read()

                if let message = result.context.blackMessage,
                   let resultType = BlackProtocol.MessageType(message),
                   resultType == type {

                    #if DEBUG
                    debugLog("read data of size \(result.data.count)")
                    #endif

                    return result.data
                }
            } while true
        }

        private func state(changed to: NWConnection.State) {
            #if DEBUG
            self.debugLog("status \(to)")
            #endif

            stateSubject.send(to)
        }
    }
}


extension Network.NW {
    class InboundConnection : Connection {
        #if DEBUG
        override var debugKind: String { return "inbound" }
        #endif

        @Published var indentifier: Data?
        
        override init(connection: NWConnection) {
            super.init(connection: connection)
        }
        
        func start(_ timeout: TimeInterval = 10) async throws -> Data {
            try await super.start()
            return try await read(.identity)
        }
    }
}


extension Network.NW {
    class OutboundConnection : Connection {
        #if DEBUG
        override var debugKind: String { return "outbound" }
        #endif
        
        private let identifier: Data

        init(endpoint: NWEndpoint, identifier: Data, passcode: String) {
            let parameters = NWParameters(passcode: passcode)
            
            self.identifier = identifier
            super.init(connection: NWConnection(to: endpoint, using: parameters))
        }
        
        override func start() async throws {
            try await super.start()
            try await sendAsync(identifier, of: .identity)
        }
    }
}


extension Network.Peer.State {
    init(_ connection: Network.NW.Connection?) {
        guard connection != nil else { self = .unavailable; return }
        guard let state = connection?.state.newValue else { self = .available; return }
        self = .init(state)
    }
}

#if DEBUG
extension Network.NW.Connection : CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(debugKind) \(debugIdentifier) \(state.value.string)"
    }

    public static func debugDescription(_ connection: Network.NW.Connection?, kind: String) -> String {
        if let connection {
            return connection.debugDescription
        }
        else {
            return "\(kind) none"
        }
    }
}
#endif
