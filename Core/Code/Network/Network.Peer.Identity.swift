//
//  Network.Peer.Identity.swift
//  Core
//
//  Created by Ivan Kh on 05.04.2023.
//

import Foundation

public extension Network.Peer {
    struct Identity: Codable {
        public init(id: UInt64, name: String, kind: Network.Peer.Kind, ip: String? = nil, interface: String? = nil) {
            self.id = id
            self.name = name
            self.kind = kind
            self.ip = ip
            self.interface = interface
        }

        public let id: UInt64
        public let name: String
        public let kind: Kind
        public let ip: String?
        public let interface: String?
    }
}

public extension Network.Peer {
    struct LocalIdentity: Codable {
        public init(id: UInt64, name: String, kind: Network.Peer.Kind) {
            self.id = id
            self.name = name
            self.kind = kind
        }

        public let id: UInt64
        public let name: String
        public let kind: Kind
    }
}

public extension Network.Peer.Identity {
    static var wifi: Network.Peer.Identity {
        let wifi = Device.wifi

        return .init(id: UserDefaults.standard.peerID,
                     name: Device.name,
                     kind: .current,
                     ip: wifi?.ip,
                     interface: wifi?.name)
    }
}

fileprivate extension UserDefaults {
    var peerID: UInt64 {
        if let object = object(forKey: "peerID") as? NSNumber {
            return object.uint64Value
        }
        else {
            let result = UInt64.random(in: 0 ..< UInt64.max)
            setValue(result, forKey: "peerID")
            synchronize()
            return result
        }
    }
}

fileprivate extension Network.Peer {
    struct Serializer: Codable {
        public let a: UInt64
        public let b: String
        public let c: Kind
        public let d: String?
        public let e: String?

        init(id: UInt64, name: String, kind: Network.Peer.Kind, ip: String? = nil, interface: String? = nil) {
            self.a = id
            self.b = name
            self.c = kind
            self.d = ip
            self.e = interface
        }

        init(_ src: Identity) {
            a = src.id
            b = src.name
            c = src.kind
            d = src.ip
            e = src.interface
        }

        init(_ src: LocalIdentity) {
            a = src.id
            b = src.name
            c = src.kind
            d = nil
            e = nil
        }

        var asIdentity: Identity {
            .init(id: a, name: b, kind: c, ip: d, interface: e)
        }

        var asLocalIdentity: LocalIdentity {
            .init(id: a, name: b, kind: c)
        }
    }
}

public extension Network.Peer.Identity {
    private enum Error: Swift.Error {
        case badBase64(String)
    }

    func qrBase64() throws -> String {
        return try JSONEncoder().encode(Network.Peer.Serializer(self)).base64EncodedString()
    }

    init(base64: String) throws {
        guard let data = Data(base64Encoded: base64) else { throw Error.badBase64(base64) }
        self = try JSONDecoder().decode(Network.Peer.Serializer.self, from: data).asIdentity
    }
}

public extension Network.Peer.LocalIdentity {
    func qrData() throws -> Data {
        return try JSONEncoder().encode(Network.Peer.Serializer(self))
    }
}
