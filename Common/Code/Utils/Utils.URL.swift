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

