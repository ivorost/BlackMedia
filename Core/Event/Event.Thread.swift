//
//  Event.Thread.swift
//  Capture
//
//  Created by Ivan Kh on 25.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

extension DispatchQueue {
    static func createEventsTap() -> DispatchQueue {
        return DispatchQueue.CreateCheckable("events_tap")
    }

    static func createEventsGet() -> DispatchQueue {
        return DispatchQueue.CreateCheckable("events_get")
    }

    static func createEventsPut() -> DispatchQueue {
        return DispatchQueue.CreateCheckable("events_put")
    }
}
