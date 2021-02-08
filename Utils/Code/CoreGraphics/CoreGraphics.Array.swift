//
//  CoreGraphics.Array.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 09.06.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import CoreGraphics

public extension Array where Element == CGRect {
    func union() -> CGRect {
        return reduce(CGRect.zero) { $0.union($1) }
    }
}
