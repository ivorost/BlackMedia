//
//  Swift.String.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 12.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import Foundation

extension String : Error {
}

public extension String {
    static let empty = ""
    static let whitespace = " "
    static let lineBreak = "\n"
    static let lineBreakCharacter: Character = "\n"
    static let dot = "."
    static let doubleDot = ".."
    static let slash = "/"
    static let doubleSlash = "//"
    static let escape = "\u{1b}"
}
