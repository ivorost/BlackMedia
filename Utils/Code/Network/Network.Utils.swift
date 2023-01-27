//
//  Network.Utils.swift
//  Utils-macOS
//
//  Created by Ivan Kh on 23.12.2022.
//

import Network


extension NWConnection.State {
    public var string: String {
        switch self {
        case .setup: return "setup"
        case .waiting(_): return "waiting"
        case .preparing: return "preparing"
        case .ready: return "ready"
        case .failed: return "failed"
        case .cancelled: return "cancelled"
        @unknown default: return "-unknown-"
        }
    }
}


public extension NWParameters {
    convenience init(includePeerToPeer: Bool) {
        self.init()
        self.includePeerToPeer = includePeerToPeer
    }
}


public extension Black.Network.SessionProtocol {
    func restart() {
        stop()
        start(on: queue ?? .global())
    }

    func restart() async throws {
        await stop()
        try await start(on: queue ?? .global())
    }
}
