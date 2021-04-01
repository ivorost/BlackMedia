//
//  Target.App.Delegate.swift
//  Common
//
//  Created by Ivan Kh on 19.02.2021.
//

#if os(OSX)
import Cocoa
#else
import UIKit
#endif



#if os(OSX)
open class AppDelegate : NSObject {
    
}
#else
open class AppDelegate : UIResponder, UIApplicationDelegate {
    
}
#endif


#if os(OSX)
extension AppDelegate : NSApplicationDelegate {
    open func applicationDidFinishLaunching(_ aNotification: Notification) {
        try? FileManager.default.createDirectory(at: .appSettings,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
    }
}
#endif
