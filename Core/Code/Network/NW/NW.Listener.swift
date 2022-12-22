/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implement a TLS listener that advertises your game's Bonjour service.
*/

import Network
import Combine

public extension Network.NW {
    class Listener {
        func debugLog(_ string: String) {
            #if DEBUG
            print("Listener: \(string)")
            #endif
        }
        
        enum ListenerError : Error {
            case cancelled
        }

        private let peers: PeerStore
        private var listener: NWListener?
        private var endpointName: EndpointName
        private let passcode: String
        private let serviceName: String
        private var connections = [Connection]()
        @Published private var state: NWListener.State?

        // Create a listener with a name to advertise, a passcode for authentication,
        // and a delegate to handle inbound connections.
        init(peers: PeerStore,
             endpoint endpointName: EndpointName,
             service serviceName: String,
             passcode: String) {
            self.peers = peers
            self.endpointName = endpointName
            self.passcode = passcode
            self.serviceName = serviceName
        }

        // Start listening and advertising.
        public func start() throws {
            do {
                // Create the listener object.
                let listener = try NWListener(using: NWParameters(passcode: passcode))
                self.listener = listener

                listener.service = NWListener.Service(name: self.endpointName.encoded, type: serviceName)
                listener.stateUpdateHandler = state(changed:)
                listener.newConnectionHandler = inbound(connection:)
                listener.start(queue: .main)
            }
            catch {
                print("Listener: error \(error)")
                throw error
            }
        }
        
        public func start() async throws {
            var disposable: AnyCancellable?

            try await withCheckedThrowingContinuation { continuation in
                do {
                    disposable = $state.sink { newValue in
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

                    try start()
                }
                catch {
                    continuation.resume(throwing: error)
                }
            } as Void
        }
        
        func stop() async {
            
        }
        
        private func state(changed to: NWListener.State) {
            self.state = to
            
            switch to {
            case .ready:
                debugLog("ready on \(String(describing: listener?.port ?? 0))")
            case .failed(let error):
                // If the listener fails, re-start.
                if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
                    debugLog("failed with \(error), restarting")
                    listener?.cancel()
                } else {
                    debugLog("failed with \(error), stopping")
                    listener?.cancel()
                }
            case .cancelled:
                debugLog("cancelled")
                break
            default:
                debugLog("Unknown state \(to)")
                break
            }
        }
        
        private func inbound(connection: NWConnection) {
            Task { [weak self] in
                let connection = InboundConnection(connection: connection)

                do {
                    self?.debugLog("Inbound connection \(connection.debugIdentifier) AAAA")
                    let endpointName: EndpointName
                    let endpointNameData = try await connection.start()
                    guard let endpointNameString = String(data: endpointNameData, encoding: .utf8) else { return }

                    endpointName = .decode(endpointNameString)
                    self?.debugLog("received connection \(connection.debugIdentifier) for \(endpointName.pin) \(endpointName.name)")
                    await self?.peers.received(connection: connection, for: endpointName)
                    self?.debugLog("Inbound connection \(connection.debugIdentifier) ZZZZ")
                }
                catch {
                    #if DEBUG
                    self?.debugLog("Inbound connection \(connection.debugIdentifier) ZZZZ error \(error)")
                    #endif
                }
            }
        }
    }
}

