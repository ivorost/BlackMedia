//
//  Target.App.Delegate.swift
//  Common
//
//  Created by Ivan Kh on 19.02.2021.
//

import Cocoa


open class AppDelegate : NSObject {
    
}


#if os(OSX)
extension AppDelegate : NSApplicationDelegate {
    open func applicationDidFinishLaunching(_ aNotification: Notification) {
        try? FileManager.default.createDirectory(at: .appSettings,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
    }
}
#endif
