//
//  Video.Time.swift
//  Capture
//
//  Created by Ivan Kh on 02.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation

struct VideoTime {
    let timeStamp: CaptureTime
    let timeScale: Int32
    
    init() {
        timeStamp = 0
        timeScale = 0
    }
    
    init(timeStamp: Float64, timeScale: Int32) {
        self.timeStamp = timeStamp
        self.timeScale = timeScale
    }
    
    func copy(timeStamp: Float64) -> VideoTime {
        return VideoTime(timeStamp: timeStamp, timeScale: timeScale)
    }
}

extension VideoTime {
    
    init(_ x: CMSampleTimingInfo) {
        self.init(timeStamp: CMTimeGetSeconds(x.presentationTimeStamp), timeScale: x.presentationTimeStamp.timescale)
    }
    
    var cmSampleTimingInfo: CMSampleTimingInfo {
        var result = CMSampleTimingInfo()
        
        result.presentationTimeStamp.flags = .valid
        result.presentationTimeStamp.timescale = timeScale
        CMTimeSetSeconds(&result.presentationTimeStamp, timeStamp)
        
        return result
    }
}

extension VideoTime : StructProtocol {
}
