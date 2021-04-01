//
//  CoreGraphics.Event.swift
//  Capture
//
//  Created by Ivan Kh on 27.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import CoreGraphics

#if os(OSX)
public extension CGEvent {
    var isMouse: Bool {
        switch type {
        case .leftMouseDown,
             .leftMouseDragged,
             .leftMouseUp,
             .mouseMoved,
             .otherMouseDown,
             .otherMouseDragged,
             .otherMouseUp,
             .rightMouseDown,
             .rightMouseDragged,
             .rightMouseUp,
             .scrollWheel:
            return true
        default:
            return false
        }
    }
    
    var mouseButton: CGMouseButton? {
        switch type {
        case .leftMouseDown, .leftMouseDragged, .leftMouseUp:
             return .left
        case .otherMouseDown, .otherMouseDragged, .otherMouseUp:
             return .center
        case .rightMouseDown, .rightMouseDragged, .rightMouseUp:
            return .right
        case .mouseMoved:
            return .left
        default:
            return nil
        }
    }
}
#endif
