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
        private var inner: Black.Network.Listener?
        private var endpointName: EndpointName
        private let passcode: String
        private let serviceName: String
        private var connections = [Connection]()
        private var cancellables = [AnyCancellable]()

        init(peers: PeerStore,
             endpoint endpointName: EndpointName,
             service serviceName: String,
             passcode: String) {
            self.peers = peers
            self.endpointName = endpointName
            self.passcode = passcode
            self.serviceName = serviceName
        }

        public func start(on queue: DispatchQueue = .global()) async throws {
            do {
                let listener = try NWListener(using: NWParameters(passcode: passcode))
                listener.service = NWListener.Service(name: self.endpointName.encoded, type: serviceName)

                self.inner = Black.Network.Listener(listener)
                inner?.state.sink(receiveValue: state(changed:)).store(in: &cancellables)
                inner?.connection.sink(receiveValue: inbound(connection:)).store(in: &cancellables)
                try await self.inner?.start(on: queue)
            }
            catch {
                debugLog("failed to start \(error)")
                throw error
            }
        }
        
        func stop() async {
            await inner?.stop()
        }
        
        private func state(changed to: NWListener.State) {
            switch to {
            case .ready:
                debugLog("ready on \(String(describing: inner?.inner.port ?? 0))")
            case .failed(let error):
                if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
                    debugLog("failed with \(error), restarting")
                    inner?.restart()
                }
                else {
                    debugLog("failed with \(error), stopping")
                    inner?.stop()
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
                    #if DEBUG
                    self?.debugLog("Inbound connection \(connection.debugIdentifier) AAAA")
                    #endif

                    let endpointName: EndpointName
                    let endpointNameData = try await connection.start()
                    guard let endpointNameString = String(data: endpointNameData, encoding: .utf8) else { return }

                    endpointName = .decode(endpointNameString)

                    #if DEBUG
                    self?.debugLog("received connection \(connection.debugIdentifier) for \(endpointName.pin) \(endpointName.name)")
                    #endif

                    await self?.peers.received(connection: connection, for: endpointName)

                    #if DEBUG
                    self?.debugLog("Inbound connection \(connection.debugIdentifier) ZZZZ")
                    #endif
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

