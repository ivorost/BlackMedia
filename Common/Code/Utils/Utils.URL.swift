//
//  Utils.URL.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 30.04.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import Foundation

public extension URL {

    static var applicationData: URL? {
        guard
            let bundleID = Bundle.main.bundleIdentifier,
            let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory,
                                                                 in: .userDomainMask).first
            else { assert(false); return nil }
        
        return applicationSupportURL.appendingPathComponent(bundleID)
    }
    
    static var captureCamera: URL? {
        return applicationData?.appendingPathComponent("camera")
    }

    static var captureScreen: URL? {
        return applicationData?.appendingPathComponent("screen")
    }
}


public extension URL {
    static var wsSenderData: URL? {
        return URL(string: String.wsSender.updating(name: "machine_mac_data"))
    }

    static var wsSenderHelm: URL? {
        return URL(string: String.wsSender.updating(name: "machine_mac_helm"))
    }

    static var wsReceiverData: URL? {
        return URL(string: String.wsReceiver.updating(name: "machine_mac_data"))
    }

    static var wsReceiverHelm: URL? {
        return URL(string: String.wsReceiver.updating(name: "machine_mac_helm"))
    }
    
    static var wsLocalhost: URL? {
        return URL(string: "ws://localhost:1337?room=test")
    }

    static var wsLocalhostData: URL? {
        return URL(string: "ws://localhost:1337?room=test_data")
    }

    static var wsLocalhostHelm: URL? {
        return URL(string: "ws://localhost:1337?room=test_helm")
    }
}


fileprivate extension String {
    static let wsSender =
    """
    ws://relay.raghava.io/proxy/connect?username=fL1VmUj0bK&machine_id=machine_mac&action=start_host_machine&token=vu8kd7ovvcJqp4uQeuD6OZQCUtWzX8BxeV7W1mq6fDdgsOkpVQeiTe73n6eleYvW6Nzom5fAWEJP5r6TBRUsx7tv6htvgIhdgEKqzKNfQ2G8d5CPUudhrvR6l4lc4TuuCHxdzZycSRCFQrraIUCYGujiArWe2ei7FuVZ1juerRSsrQ95ZUzlOIJJO7lGlNEupIxrHSgKt8F3e95802zsNcWsWh8Vgky985TXqq8gELVqK4VD692noib5bZU9GAy
    """

    static let wsReceiver =
    """
    ws://relay.raghava.io/proxy/connect?username=fL1VmUj0bK&machine_id=machine_mac&action=connect_to_host_machine&token=vu8kd7ovvcJqp4uQeuD6OZQCUtWzX8BxeV7W1mq6fDdgsOkpVQeiTe73n6eleYvW6Nzom5fAWEJP5r6TBRUsx7tv6htvgIhdgEKqzKNfQ2G8d5CPUudhrvR6l4lc4TuuCHxdzZycSRCFQrraIUCYGujiArWe2ei7FuVZ1juerRSsrQ95ZUzlOIJJO7lGlNEupIxrHSgKt8F3e95802zsNcWsWh8Vgky985TXqq8gELVqK4VD692noib5bZU9GAy
    """

    func updating(name: String) -> String {
        let urlStringPath = Settings.shared.server
        var result = self
        
        result = result.replacingOccurrences(of: "machine_mac", with: name)
        result = result.replacingOccurrences(of: "ws://relay.raghava.io/proxy", with: urlStringPath)
        
        return result
    }
}
