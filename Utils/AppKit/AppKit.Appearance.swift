//
//  AppKit.Appearance.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 02.07.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AppKit

public extension NSAppearance {
    var isDark: Bool {
        if #available(OSX 10.14, *) {
            return self.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        }
        else {
            return false
        }
    }
    
    var isAqua: Bool {
        return !isDark
    }
}

public extension NSApplication {
    var isDark: Bool {
        if #available(OSX 10.14, *) {
            return self.effectiveAppearance.isDark
        }
        else {
            return false
        }
    }
    
    var isAqua: Bool {
        return !isDark
    }
}
