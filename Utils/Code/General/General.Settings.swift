//
//  General.Settings.swift
//  Utils
//
//  Created by Ivan Kh on 19.02.2021.
//

import Foundation

#if os(OSX)
fileprivate extension URL {
    static let appSettingsPath = appSettings.appendingPathComponent("app.xml")
}
#endif


public class Settings {
    public typealias Key = String

    #if os(OSX)
    public init() {}
    
    open func readSetting<T>(_ forKey: Key) -> T? {
        let plistContents = NSDictionary(contentsOf: .appSettingsPath)
        return plistContents?[forKey] as? T
    }
    
    open func writeSetting(_ key: Key, _ val: Any?) {
        let plistContents = NSMutableDictionary(contentsOf: .appSettingsPath) ?? NSMutableDictionary()
                
        plistContents[key] = val
        plistContents.write(to: .appSettingsPath, atomically: true)
    }
    #else
    private let userDefaults: UserDefaults
    
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    open func readSetting<T>(_ forKey: Key) -> T? {
        return userDefaults.value(forKey: forKey) as? T
    }

    open func writeSetting(_ key: Key, _ val: Any?) {
        userDefaults.set(val, forKey: key)
    }
    #endif
}
