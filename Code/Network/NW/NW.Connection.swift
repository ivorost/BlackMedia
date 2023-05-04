/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implement a TLS connection that supports the custom GameProtocol framing protocol.
*/

import Foundation
import Network
import Combine
import BlackUtils

// en0 and en1 are your hardware interfaces (usually Ethernet and WiFi)
// en2, en3, en4 wired
// pdp_ip0, pdp_ip1 ... cellular
// awdl0 is Apple Wireless Direct Link (Bluetooth)
// lo is the loopback interface
// p2p0 is a point to point link (usually VPN)
// stf0 is a "six to four" interface (IPv6 to IPv4)
// gif01 is a software interface
// bridge0 is a software bridge between other interfaces
// utun0 is used for "Back to My Mac"
// XHC20 is a USB network interface

public extension Network.NW {
    class Connection {
        #if DEBUG
        static var debugIdentifier = 0
        let debugIdentifier: Int
        var debugKind: String { return "unknown" }
        func debugLog(_ string: String) { print("Connection \(debugKind) \(debugIdentifier): \(string)") }
        #else
        @inlinable func debugLog(_ string: String) { }
        #endif
        
        public var state: AnyNewValuePublisher<NWConnection.State, Never> { stateSubject.eraseToAnyNewValuePublisher() }
        fileprivate let stateSubject = KeepValueSubject<NWConnection.State, Never>(.setup)

        public var data: AnyPublisher<Network.Peer.Data, Error> { dataSubject.eraseToAnyPublisher() }
        private let dataSubject = PassthroughSubject<Network.Peer.Data, Error>()

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
            inner.data.compactMap { .init(type: BlackProtocol.MessageType($0.context.blackMessage), data: $0.data) }
                .subscribe(dataSubject)
                .store(in: &cancellables)

            debugLog("init \(debugKind)")
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
            debugLog("starting")
            try await inner.start()
            debugLog("started")
        }

        func stop() async {
            debugLog("stopping")
            await inner.stop()
            debugLog("stoped")
        }

        func sendAsync(_ data: Data, of type: BlackProtocol.MessageType = .data) async throws {
            let message = NWProtocolFramer.Message(type)
            let context = NWConnection.ContentContext(identifier: "black", metadata: [message])

//            debugLog("send async data of size \(data.count) (\(String(describing: state.value)))")
            try await inner.sendAsync(data, in: context)
        }
        
        func send(_ data: Data, of type: BlackProtocol.MessageType = .data) {
            let message = NWProtocolFramer.Message(type)
            let context = NWConnection.ContentContext(identifier: "black", metadata: [message])

//            debugLog("send data of size \(data.count) (\(String(describing: state.value)))")
            inner.send(data, in: context)
        }
        
        func read(_ type: BlackProtocol.MessageType = .data) async throws -> Data {
            repeat {
                let result = try await inner.read()

                if let message = result.context.blackMessage,
                   let resultType = BlackProtocol.MessageType(message),
                   resultType == type {

                    debugLog("read data of size \(result.data.count)")
                    return result.data
                }
            } while true
        }

        private func state(changed to: NWConnection.State) {
            self.debugLog("status \(to)")
            stateSubject.send(to)
        }
    }
}

public extension Network.NW.Connection {
    func send(_ data: Network.Peer.Data) {
        switch data {
        case .data(let data):
            send(data, of: .data)
        case .pair:
            send(Data(), of: .pair)
        case .skip:
            send(Data(), of: .skip)
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
        
        private let information: Network.Peer.Information.AnyProto

        init(endpoint: NWEndpoint, information: Network.Peer.Information.AnyProto, passcode: String) {
            let parameters = NWParameters(passcode: passcode)
            
            self.information = information
            super.init(connection: NWConnection(to: endpoint, using: parameters))
        }
        
        override func start() async throws {
            let informationData = try JSONEncoder().encode(information.dictionary)
            try await super.start()
            try await sendAsync(informationData, of: .identity)
        }
    }
}


#if DEBUG
extension Network.NW.Connection : CustomDebugStringConvertible {
    public var debugDescription: String {
        let interfaceDescription: String

        if let availableInterfaces = inner.path.newValue?.availableInterfaces {
            interfaceDescription = availableInterfaces
                .map { "\($0.type).\($0.name)" }
                .joined(separator: ", ")
        }
        else {
            interfaceDescription = ""
        }

        return "\(debugKind) \(debugIdentifier) \(state.newValue.string) [\(interfaceDescription)]"
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
