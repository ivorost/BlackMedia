//
//  CoreGraphics.General.swift
//  Capture
//
//  Created by Ivan Kh on 07.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import CoreGraphics

extension CGPoint {
    static func +=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }

    static func -=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
    }
}
