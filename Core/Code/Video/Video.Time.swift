//
//  Video.Time.swift
//  Capture
//
//  Created by Ivan Kh on 02.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation

struct VideoTime {
    let timestamp: CaptureTime
    let duration: CaptureTime
    
    init() {
        timestamp = CaptureTime()
        duration = CaptureTime()
    }
    
    init(timestamp: CaptureTime, duration: CaptureTime) {
        self.timestamp = timestamp
        self.duration = duration
    }
}

extension VideoTime {
    
    init(_ x: CMSampleTimingInfo) {
        self.init(timestamp: CaptureTime(x.presentationTimeStamp), duration: CaptureTime(x.duration))
    }
    
    var cmSampleTimingInfo: CMSampleTimingInfo {
        return CMSampleTimingInfo(duration: duration.cmTime,
                                  presentationTimeStamp: timestamp.cmTime,
                                  decodeTimeStamp: timestamp.cmTime)
    }
    
    func relative(to timebase: VideoTime) -> VideoTime {
        return VideoTime(timestamp: timestamp.substract(timebase.timestamp), duration: duration)
        
    }
}

extension VideoTime : StructProtocol {
}
