//
//  App.Settings.swift
//  Application-macOS
//
//  Created by Ivan Kh on 19.02.2021.
//

import Foundation

fileprivate extension Settings.Key {
    static let fileURL: Settings.Key = "fileURL"
    static let sizeToFit: Settings.Key = "sizeToFit"
    static let sizeToOriginal: Settings.Key = "sizeToOriginal"
}

extension Settings {
    public var fileURL: URL? {
        get {
            guard
                let base64: String = readSetting(.fileURL),
                let data = Data(base64Encoded: base64)
            else { return nil }
            
            var isStale = false
            return try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
        }
        set {
            writeSetting(.fileURL, try? newValue?.bookmarkData().base64EncodedString())
        }
    }

    var sizeToOriginal: Bool {
        get { return readSetting(.sizeToOriginal) ?? false }
        set { writeSetting(.sizeToOriginal, newValue) }
    }
}
