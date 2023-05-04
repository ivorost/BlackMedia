/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implement a TLS listener that advertises your game's Bonjour service.
*/

import Foundation
import Network
import Combine
import BlackUtils

public extension Network.NW {
    class Listener<TInformation: PeerInformation> {
        func debugLog(_ string: String) {
            #if DEBUG
            print("Listener: \(string)")
            #endif
        }
        
        enum ListenerError : Error {
            case cancelled
        }

        private let peers: PeerStore<TInformation>
        private var inner: Black.Network.Listener?
        private var identity: Network.Peer.Identity
        private let passcode: String
        private let serviceName: String
        private var connections = [Connection]()
        private var cancellables = [AnyCancellable]()

        init(peers: PeerStore<TInformation>,
             identity: Network.Peer.Identity,
             service serviceName: String,
             passcode: String) {
            self.peers = peers
            self.identity = identity
            self.passcode = passcode
            self.serviceName = serviceName
        }

        public func start(on queue: DispatchQueue = .global()) async throws {
            do {
                let listener = try NWListener(using: NWParameters(passcode: passcode))
                listener.service = NWListener.Service(name: identity.unique.uuidString,
                                                      type: serviceName,
                                                      txtRecord: NWTXTRecord(identity.dictionary))

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

                    let informationData = try await connection.start()
                    let informationDictionary = try JSONDecoder().decode([String: String].self, from: informationData)
                    let information = try TInformation(informationDictionary)

                    #if DEBUG
                    self?.debugLog("received connection \(connection.debugIdentifier) for \(information.id.name)")
                    #endif

                    await self?.peers.received(connection: connection, for: information)

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

