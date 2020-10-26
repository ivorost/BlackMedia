//
//  Foundation.URL.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 14.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import Foundation

public extension URL {
    var isFilePathRoot: Bool {
        return path == "/"
    }
    
    func isDirectory() throws -> Bool? {
        return try resourceValues(forKeys: [.isDirectoryKey]).isDirectory
    }
    
    func fileSize() throws -> Int? {
        return try resourceValues(forKeys: [.fileSizeKey]).fileSize
    }

    func contentAccessDate() throws -> Date? {
        return try resourceValues(forKeys: [.contentAccessDateKey]).contentAccessDate
    }
}