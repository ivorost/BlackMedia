//
//  App.Settings.swift
//  Capture
//
//  Created by Ivan Kh on 04.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation


fileprivate extension Settings.Key {
    #if os(OSX)
    static let display: Settings.Key = "display"
    static let events: Settings.Key = "events"
    static let networking: Settings.Key = "networking"
    static let duplicates: Settings.Key = "duplicates"
    static let multithread: Settings.Key = "multithread"
    static let preview: Settings.Key = "preview"
    static let acknowledge: Settings.Key = "acknowledge"
    static let stream: Settings.Key = "stream"
    static let metal: Settings.Key = "metal"
    static let memcmp: Settings.Key = "memcmp"
    #endif
    static let server: Settings.Key = "server"
}


public extension Settings {
    #if os(OSX)
    static let shared = Settings()
    #else
    static let shared = Settings(userDefaults: UserDefaults(suiteName: "group.com.idrive.screentest"))
    #endif
}


extension Settings {
    public var server: String {
        get { return readSetting(.server) ?? "ws://relay.raghava.io/proxy" }
        set { writeSetting(.server, newValue) }
    }
}


#if os(OSX)
extension Settings {
    public var display: Bool {
        get { return readSetting(.display) ?? true }
        set { writeSetting(.display, newValue) }
    }

    public var events: Bool {
        get { return readSetting(.events) ?? true }
        set { writeSetting(.events, newValue) }
    }

    public var networking: Bool {
        get { return readSetting(.networking) ?? true }
        set { writeSetting(.networking, newValue) }
    }

    public var duplicates: Bool {
        get { return readSetting(.duplicates) ?? true }
        set { writeSetting(.duplicates, newValue) }
    }
    
    public var multithread: Bool {
        get { return readSetting(.multithread) ?? true }
        set { writeSetting(.multithread, newValue) }
    }

    public var preview: Bool {
        get { return readSetting(.preview) ?? false }
        set { writeSetting(.preview, newValue) }
    }

    public var acknowledge: Bool {
        get { return readSetting(.acknowledge) ?? true }
        set { writeSetting(.acknowledge, newValue) }
    }
    
    public var stream: Bool {
        get { return readSetting(.stream) ?? false }
        set { writeSetting(.stream, newValue) }
    }

    public var metal: Bool {
        get { return readSetting(.metal) ?? true }
        set { writeSetting(.metal, newValue) }
    }
    
    public var memcmp: Bool {
        get { return readSetting(.memcmp) ?? false }
        set { writeSetting(.memcmp, newValue) }
    }
}
#endif
