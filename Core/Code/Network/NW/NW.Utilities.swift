/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Set up parameters for secure peer-to-peer connections and listeners.
*/

import Network
import CryptoKit

extension NWParameters {

	// Create parameters for use in PeerConnection and PeerListener.
	convenience init(passcode: String) {
		// Customize TCP options to enable keepalives.
		let tcpOptions = NWProtocolTCP.Options()
		tcpOptions.enableKeepalive = true
		tcpOptions.keepaliveIdle = 2

		// Create parameters with custom TLS and TCP options.
		self.init(tls: NWParameters.tlsOptions(passcode: passcode), tcp: tcpOptions)

		// Enable using a peer-to-peer link.
		self.includePeerToPeer = true

//		// Add your custom game protocol to support game messages.
        let options = NWProtocolFramer.Options(definition: Network.NW.BlackProtocol.definition)
        self.defaultProtocolStack.applicationProtocols.insert(options, at: 0)
	}

	// Create TLS options using a passcode to derive a pre-shared key.
	private static func tlsOptions(passcode: String) -> NWProtocolTLS.Options {
		let tlsOptions = NWProtocolTLS.Options()

		let authenticationKey = SymmetricKey(data: passcode.data(using: .utf8)!)
		var authenticationCode = HMAC<SHA256>.authenticationCode(for: "VideoNanny".data(using: .utf8)!,
                                                                 using: authenticationKey)

		let authenticationDispatchData = withUnsafeBytes(of: &authenticationCode) { (ptr: UnsafeRawBufferPointer) in
			DispatchData(bytes: ptr)
		}

		sec_protocol_options_add_pre_shared_key(tlsOptions.securityProtocolOptions,
												authenticationDispatchData as __DispatchData,
												stringToDispatchData("VideoNanny")! as __DispatchData)
		sec_protocol_options_append_tls_ciphersuite(tlsOptions.securityProtocolOptions,
                                                    tls_ciphersuite_t(rawValue: UInt16(TLS_PSK_WITH_AES_128_GCM_SHA256))!)
		return tlsOptions
	}

	// Create a utility function to encode strings as pre-shared key data.
	private static func stringToDispatchData(_ string: String) -> DispatchData? {
		guard let stringData = string.data(using: .unicode) else {
			return nil
		}
		let dispatchData = withUnsafeBytes(of: stringData) { (ptr: UnsafeRawBufferPointer) in
			DispatchData(bytes: UnsafeRawBufferPointer(start: ptr.baseAddress, count: stringData.count))
		}
		return dispatchData
	}
}

public extension Network.NW {
    struct EndpointName : Equatable {
        let pin: String
        let name: String
        let kind: Network.Peer.Kind
        
        var encoded: String {
            return "\(pin)\(kind.rawValue)\(name)"
        }

        static var generateID: String {
            "\(Int.random(in: 1000 ..< 10000))"
        }

        static func encode(name: String, kind: Network.Peer.Kind) -> EndpointName {
            return EndpointName(pin: generateID, name: name, kind: kind)
        }
        
        static func decode(_ value: String) -> EndpointName {
            let pin = String(value.prefix(4))
            let kind = UInt64(value[value.index(value.startIndex, offsetBy: 4)].wholeNumberValue ?? 0)
            let decodedName = String(value.suffix(from: value.index(value.startIndex, offsetBy: 5)))
            
            return EndpointName(pin: pin, name: decodedName, kind: .init(rawValue: kind) ?? .unknown)
        }
    }
}

extension Network.Peer.State {
    init(_ state: NWConnection.State) {
        switch state {
        case .ready: self = .connected
        case .setup: self = .connecting
        case .preparing: self = .connecting
        case .waiting(_): self = .connecting
        case .cancelled: self = .disconnected
        case .failed(_): self = .disconnected
        @unknown default: self = .unavailable
        }
    }
}