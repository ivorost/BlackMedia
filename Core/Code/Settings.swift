//
//  App.Settings.swift
//  Capture
//
//  Created by Ivan Kh on 04.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

fileprivate extension String {
    static let plistFileName = "Swiftify.Xcode.Extension.plist"
}


fileprivate typealias Key = String
fileprivate extension Key {
    #if os(OSX)
    static let display: Key = "display"
    static let events: Key = "events"
    static let networking: Key = "networking"
    static let duplicates: Key = "duplicates"
    static let multithread: Key = "multithread"
    static let preview: Key = "preview"
    static let acknowledge: Key = "acknowledge"
    static let stream: Key = "stream"
    static let metal: Key = "metal"
    static let memcmp: Key = "memcmp"
    #endif
    static let server: Key = "server"
}


#if os(OSX)
extension URL {
    static let appSettingsPath = appSettings.appendingPathComponent("app.xml")
}
#endif

public class Settings {
    public static let shared = Settings()
}


extension Settings {
    #if os(OSX)
    private func readSetting<T>(_ forKey: Key) -> T? {
        let plistContents = NSDictionary(contentsOf: .appSettingsPath)
        return plistContents?[forKey] as? T
    }
    
    private func writeSetting(_ key: Key, _ val: Any?) {
        let plistContents = NSMutableDictionary(contentsOf: .appSettingsPath) ?? NSMutableDictionary()
        
        plistContents[key] = val
        plistContents.write(to: .appSettingsPath, atomically: false)
    }
    #else
    private static let userDefaults = UserDefaults(suiteName: "group.com.idrive.screentest")
    
    private func readSetting<T>(_ forKey: Key) -> T? {
        return Settings.userDefaults?.value(forKey: forKey) as? T
    }

    private func writeSetting(_ key: Key, _ val: Any?) {
        Settings.userDefaults?.set(val, forKey: key)
    }
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
