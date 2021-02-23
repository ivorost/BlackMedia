//
//  AppDelegate.swift
//  Application
//
//  Created by Ivan Kh on 15.02.2021.
//

import Cocoa

@NSApplicationMain
class AppDelegate: Common.AppDelegate {

    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        super.applicationDidFinishLaunching(aNotification)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
}

