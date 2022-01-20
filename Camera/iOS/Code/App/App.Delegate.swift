//
//  AppDelegate.swift
//  CaptureIOS
//
//  Created by Ivan Kh on 17.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        (window?.rootViewController as? AppController)?.peersDiscovery?.stop()
    }
}

