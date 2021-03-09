//
//  App.Settings.swift
//  Application-macOS
//
//  Created by Ivan Kh on 19.02.2021.
//

import Foundation


extension Settings.Key {
    static let fileURL1: Settings.Key = "fileURL1"
    static let fileURL2: Settings.Key = "fileURL2"
    static let fileURL3: Settings.Key = "fileURL3"
    static let fileURL4: Settings.Key = "fileURL4"
    static let sizeToOriginal: Settings.Key = "sizeToOriginal"
    static let modeCombine: Settings.Key = "modeCombine"
}


extension Settings {
    public var fileURL1: URL? {
        get { readSetting(.fileURL1) }
        set { writeSetting(.fileURL1, newValue) }
    }

    public var fileURL2: URL? {
        get { readSetting(.fileURL2) }
        set { writeSetting(.fileURL2, newValue) }
    }

    public var fileURL3: URL? {
        get { readSetting(.fileURL3) }
        set { writeSetting(.fileURL3, newValue) }
    }

    public var fileURL4: URL? {
        get { readSetting(.fileURL4) }
        set { writeSetting(.fileURL4, newValue) }
    }

    var sizeToOriginal: Bool {
        get { readSetting(.sizeToOriginal) ?? false }
        set { writeSetting(.sizeToOriginal, newValue) }
    }

    var modeCombine: Bool? {
        get { readSetting(.modeCombine) }
        set { writeSetting(.modeCombine, newValue) }
    }
}
