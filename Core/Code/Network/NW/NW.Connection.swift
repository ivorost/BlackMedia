/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implement a TLS connection that supports the custom GameProtocol framing protocol.
*/

import Foundation
import Network
import Combine


public extension Network.NW {
    class Connection : ObservableObject {

        enum ConnectionError : Swift.Error {
            case cancelled
        }

        #if DEBUG
        static var debugIdentifier = 0
        let debugIdentifier: Int
        var connectionType: String { return "unknown" }
        func debugLog(_ string: String) { print("Connection \(debugIdentifier): \(string)") }
        #endif
        
        @Published var state: NWConnection.State?
        @Published var data: Data = Data()
        @Published var error: Error?
        @Published private var dataInternal: (data: Data, type: BlackProtocol.MessageType)?
        private var dataDisposable: AnyCancellable?
        private let connection: NWConnection
        private var receivingData = false

        fileprivate init(connection: NWConnection) {
            #if DEBUG
            Connection.debugIdentifier += 1
            debugIdentifier = Connection.debugIdentifier
            #endif

            self.connection = connection
            self.dataDisposable = self.$dataInternal.sink { [weak self] data in
                if let data = data?.data {
                    self?.data = data
                }
            }

            subscribeForStatus()

            #if DEBUG
            debugLog("init \(connectionType)")
            #endif
        }
        
        fileprivate func start() async throws {
            var disposable: AnyCancellable?

            try await withCheckedThrowingContinuation { continuation in
                disposable = $state.sink { newValue in
                    switch newValue {
                    case .ready:
                        disposable?.cancel()
                        continuation.resume()
                    case .failed(let error):
                        disposable?.cancel()
                        continuation.resume(throwing: error)
                    case .cancelled:
                        disposable?.cancel()
                        continuation.resume(throwing: ConnectionError.cancelled)
                    default:
                        break
                    }
                }
                
                connection.start(queue: .main)
                
                #if DEBUG
                debugLog("start")
                #endif
            }

            #if DEBUG
            debugLog("started")
            #endif
        }

        func stop() async {
            var disposable: AnyCancellable?
            
            await withCheckedContinuation { continuation in
                disposable = $state.sink { newValue in
                    switch newValue {
                    case .failed(_):
                        disposable?.cancel()
                        continuation.resume()
                    case .cancelled:
                        disposable?.cancel()
                        continuation.resume()
                    default:
                        break
                    }
                }

                connection.cancel()
                
                #if DEBUG
                debugLog("stop")
                #endif
            } as Void
        }

        func send(_ data: Data, of type: BlackProtocol.MessageType = .data) async throws {
            try await withCheckedThrowingContinuation { continuation in
                let message = NWProtocolFramer.Message(type)
                let context = NWConnection.ContentContext(identifier: "black", metadata: [message])

                // Send the app content along with the message.
                connection.send(content: data,
                                contentContext: context,
                                isComplete: true,
                                completion: .contentProcessed { error in
                    if let error = error {
                        print("\(error)")
                        continuation.resume(throwing: error)
                    }
                    else {
                        continuation.resume()
                    }
                })
            } as Void
            
            #if DEBUG
//            debugLog("send data of size \(data.count) (\(String(describing: state)))")
            #endif
        }
        
        func send(_ data: Data) {
            Task {
                try? await send(data, of: .data)
            }
        }
        
        func read(_ type: BlackProtocol.MessageType = .data) async throws -> Data {
            var dataDisposable: AnyCancellable?
            var errorDisposable: AnyCancellable?
            var stateDisposable: AnyCancellable?

            let cancelDisposable = {
                dataDisposable?.cancel()
                errorDisposable?.cancel()
                stateDisposable?.cancel()
            }

            let result = try await withCheckedThrowingContinuation { continuation in
                dataDisposable = $dataInternal.sink { data in
                    if let data = data, data.type == type {
                        cancelDisposable()
                        continuation.resume(returning: data)
                    }
                }
                
                errorDisposable = $error.sink { error in
                    if let error = error {
                        cancelDisposable()
                        continuation.resume(throwing: error)
                    }
                }
                
                stateDisposable = $state.sink { state in
                    if state != .ready {
                        cancelDisposable()
                        continuation.resume(throwing: ConnectionError.cancelled)
                    }
                }
                
                if !receivingData {
                    listenForData()
                }
            }
            
            #if DEBUG
            debugLog("read data of size \(result.data.count)")
            #endif
            
            return result.data
        }
        
        fileprivate func listenForData() {
            receivingData = true
  
            connection.receiveMessage { [weak self] completeContent, contentContext, isComplete, error in
                if let error = error {
                    self?.error = error
                }
                else if let message = contentContext?.blackMessage, let type = BlackProtocol.MessageType(message) {
                    self?.dataInternal = (completeContent ?? Data(), type)
                }

                if error == nil {
                    self?.listenForData()
                }
            }
        }

        private func subscribeForStatus() {
            self.connection.stateUpdateHandler = { [weak self] newState in
                #if DEBUG
                self?.debugLog("status \(newState)")
                #endif

                switch newState {
                case .ready:
                    break

                case .failed(let error):
                    self?.connection.cancel()
                    self?.error = error

                default:
                    break
                }
                
                self?.state = newState
            }
        }
    }
}


extension Network.NW {
    class InboundConnection : Connection {
        #if DEBUG
        override var connectionType: String { return "inbound" }
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
        override var connectionType: String { return "outbound" }
        #endif
        
        private let identifier: Data

        init(endpoint: NWEndpoint, identifier: Data, passcode: String) {
            let parameters = NWParameters(passcode: passcode)
            
            self.identifier = identifier
            super.init(connection: NWConnection(to: endpoint, using: parameters))
        }
        
        override func start() async throws {
            try await super.start()
            try await send(identifier, of: .identity)
            listenForData()
        }
    }
}


extension Network.Peer.State {
    init(_ connection: Network.NW.Connection?) {
        guard connection != nil else { self = .unavailable; return }
        guard let state = connection?.state else { self = .available; return }
        self = .init(state)
    }
}
