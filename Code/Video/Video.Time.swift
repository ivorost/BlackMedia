//
//  Video.Time.swift
//  Capture
//
//  Created by Ivan Kh on 02.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation
import BlackUtils

extension Video {
    struct Time {
        let timestamp: Capture.Time
        let duration: Capture.Time
        
        init() {
            timestamp = Capture.Time()
            duration = Capture.Time()
        }
        
        init(timestamp: Capture.Time, duration: Capture.Time) {
            self.timestamp = timestamp
            self.duration = duration
        }
    }
}

extension Video.Time: BinaryCodable {
    init(from data: inout Data) throws {
        self.init(timestamp: try .init(from: &data),
                  duration: try .init(from: &data))
    }

    func encode(to data: inout Data) -> Int {
        timestamp.encode(to: &data)
        + duration.encode(to: &data)
    }
}

extension Video.Time {
    
    init(_ x: CMSampleTimingInfo) {
        self.init(timestamp: Capture.Time(x.presentationTimeStamp), duration: Capture.Time(x.duration))
    }
    
    var cmSampleTimingInfo: CMSampleTimingInfo {
        return CMSampleTimingInfo(duration: duration.cmTime,
                                  presentationTimeStamp: timestamp.cmTime,
                                  decodeTimeStamp: timestamp.cmTime)
    }
    
    func relative(to timebase: Video.Time) -> Video.Time {
        return Video.Time(timestamp: timestamp.substract(timebase.timestamp), duration: duration)
        
    }
}
