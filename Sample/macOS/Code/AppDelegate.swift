//
//  AppDelegate.swift
//  Capture
//
//  Created by Ivan Kh on 26.10.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Cocoa
import ApplicationServices

@NSApplicationMain
class AppDelegate: Common.AppDelegate {
    private var timer: Timer?

    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        super.applicationDidFinishLaunching(aNotification)
        
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        
        if !AXIsProcessTrustedWithOptions(options) {
            timer = Timer.scheduledTimer(
                withTimeInterval: 3.0,
                repeats: true) { _ in
                    self.relaunchIfProcessTrusted()
            }
        }
        
        if #available(OSX 10.15, *) {
            if !IOHIDRequestAccess(kIOHIDRequestTypeListenEvent) {
                print("bla")
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
    
    private func relaunchIfProcessTrusted() {
        if AXIsProcessTrusted() {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: Bundle.main.executablePath!)
            try! task.run()
            NSApplication.shared.terminate(self)
        }
    }
    
}
