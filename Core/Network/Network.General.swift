//
//  Network.General.swift
//  Capture
//
//  Created by Ivan Kh on 22.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

enum PacketType : UInt32 {
    case undefined = 0
    case video
    case nsevent
    case cgevent
    case display
}

