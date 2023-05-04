//
//  File.swift
//  
//
//  Created by Ivan Kh on 13.04.2023.
//

import Foundation
import BlackUtils

public protocol PeerInformation {
    var id: Network.Peer.Identity { get }
    
    init(_ dictionary: [String: String]) throws
    init(_ id: Network.Peer.Identity, dictionary: [String: String])
    var dictionary: [String: String] { get }
}

public extension Network.Peer {
    final class Information {}
}

public extension Network.Peer.Information {
    typealias Proto = PeerInformation
    typealias AnyProto = PeerInformation
}

public extension Network.Peer.Information {
    struct Basic: Proto {
        public let id: Network.Peer.Identity

        public init(_ dictionary: [String: String]) throws { self.id = try .init(dictionary) }
        public init(_ id: Network.Peer.Identity, dictionary: [String: String] = [:]) { self.id = id }
        public var dictionary: [String: String] { id.dictionary }
    }
}

//public extension Network.Peer {
//    struct EndpointName : Equatable {
//        public let pin: String
//        public let name: String
//        public let kind: Network.Peer.Kind
//
//        var encoded: String {
//            return "\(pin)\(kind.rawValue)\(name)"
//        }
//
//        static var generateID: String {
//            "\(Int.random(in: 1000 ..< 10000))"
//        }
//
//        static func encode(name: String, kind: Network.Peer.Kind) -> EndpointName {
//            return EndpointName(pin: generateID, name: name, kind: kind)
//        }
//
//        static func decode(_ value: String) -> EndpointName {
//            let pin = String(value.prefix(4))
//            let kind = UInt64(value[value.index(value.startIndex, offsetBy: 4)].wholeNumberValue ?? 0)
//            let decodedName = String(value.suffix(from: value.index(value.startIndex, offsetBy: 5)))
//
//            return EndpointName(pin: pin, name: decodedName, kind: .init(rawValue: kind) ?? .unknown)
//        }
//    }
//}


//extension UserDefaults {
//    var endpointID: String {
//        if let result = string(forKey: "endpointID") {
//            return result
//        }
//        else {
//            let result = Network.Peer.EndpointName.generateID
//            setValue(result, forKey: "endpointID")
//            synchronize()
//            return result
//        }
//    }
//}
//
//
//public extension Network.Peer.EndpointName {
//    static let current = Network.Peer.EndpointName(pin: UserDefaults.standard.endpointID,
//                                                   name: Device.name,
//                                                   kind: .current)
//    static let currentData = current.encoded.data(using: .utf8)
//}
