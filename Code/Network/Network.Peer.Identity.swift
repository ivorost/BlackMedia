//
//  Network.Peer.Information.swift
//  Core
//
//  Created by Ivan Kh on 05.04.2023.
//

import Foundation
import BlackUtils

public extension Network.Peer {
    struct Identity {
        public let unique: UUID
        public let kind: Network.Peer.Kind
        public let name: String
    }
}

extension Network.Peer.Identity: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.unique == rhs.unique
    }
}

public extension Network.Peer.Identity {
    static let local = Self.init(unique: UserDefaults.standard.peerID,
                                 kind: .current,
                                 name: Device.name)
}

fileprivate extension UserDefaults {
    var peerID: UUID {
        if let string = string(forKey: "peerID"), let result = UUID(uuidString: string) {
            return result
        }
        else {
            let result = UUID()
            setValue(result.uuidString, forKey: "peerID")
            synchronize()
            return result
        }
    }
}

extension Network.Peer.Identity {
    enum Error: Swift.Error {
        case unsupportedUUID
        case unsupportedData
        case nameSerialization(String)
    }
}

extension Network.Peer.Identity {
    init(unique: String, dictionary: [String: String]) throws {
        guard let uuid = UUID(uuidString: unique) else { throw Error.unsupportedUUID }

        self.unique = uuid
        self.name = dictionary["name"] ?? ""
        self.kind = .init(rawValue: UInt8(dictionary["kind"] ?? "") ?? 0) ?? .unknown
    }

    init(_ dictionary: [String: String]) throws {
        guard
            let uuidString = dictionary["id"],
            let uuid = UUID(uuidString: uuidString)
        else { throw Error.unsupportedUUID }

        self.unique = uuid
        self.name = dictionary["name"] ?? ""
        self.kind = .init(rawValue: UInt8(dictionary["kind"] ?? "") ?? 0) ?? .unknown
    }

    var dictionary: [String: String] {
        [
            "id": unique.uuidString,
            "name": name,
            "kind": "\(kind.rawValue)"
        ]
    }
}

//public extension Network.Peer {
//    struct Identity: Codable {
//        public init(id: UInt64, name: String, kind: Network.Peer.Kind, ip: String? = nil, interface: String? = nil) {
//            self.id = id
//            self.name = name
//            self.kind = kind
//        }
//
//        public let id: String
//        public let shortID: String
//        public let name: String
//        public let kind: Kind
//    }
//}
//
//public extension Network.Peer {
//    struct LocalIdentity: Codable {
//        public init(id: UInt64, name: String, kind: Network.Peer.Kind) {
//            self.id = id
//            self.name = name
//            self.kind = kind
//        }
//
//        public let id: UInt64
//        public let name: String
//        public let kind: Kind
//    }
//}
//
//public extension Network.Peer.Information {
//    static var wifi: Network.Peer.Information {
//        let wifi = Device.wifi
//
//        return .init(id: UserDefaults.standard.peerID,
//                     name: Device.name,
//                     kind: .current,
//                     ip: wifi?.ip,
//                     interface: wifi?.name)
//    }
//}

//fileprivate extension Network.Peer {
//    struct Serializer: Codable {
//        public let a: UInt64
//        public let b: String
//        public let c: Kind
//        public let d: String?
//        public let e: String?
//
//        init(id: UInt64, name: String, kind: Network.Peer.Kind, ip: String? = nil, interface: String? = nil) {
//            self.a = id
//            self.b = name
//            self.c = kind
//            self.d = ip
//            self.e = interface
//        }
//
//        init(_ src: Identity) {
//            a = src.id
//            b = src.name
//            c = src.kind
//            d = src.ip
//            e = src.interface
//        }
//
//        init(_ src: LocalIdentity) {
//            a = src.id
//            b = src.name
//            c = src.kind
//            d = nil
//            e = nil
//        }
//
//        var asIdentity: Identity {
//            .init(id: a, name: b, kind: c, ip: d, interface: e)
//        }
//
//        var asLocalIdentity: LocalIdentity {
//            .init(id: a, name: b, kind: c)
//        }
//    }
//}
//
//public extension Network.Peer.Information {
//    private enum Error: Swift.Error {
//        case badBase64(String)
//    }
//
//    func qrBase64() throws -> String {
//        return try JSONEncoder().encode(Network.Peer.Serializer(self)).base64EncodedString()
//    }
//
//    init(base64: String) throws {
//        guard let data = Data(base64Encoded: base64) else { throw Error.badBase64(base64) }
//        self = try JSONDecoder().decode(Network.Peer.Serializer.self, from: data).asIdentity
//    }
//}
//
//public extension Network.Peer.LocalIdentity {
//    func qrData() throws -> Data {
//        return try JSONEncoder().encode(Network.Peer.Serializer(self))
//    }
//}
