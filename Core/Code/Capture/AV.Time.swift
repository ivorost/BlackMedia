//
//  AV.Time.swift
//  Capture
//
//  Created by Ivan Kh on 02.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation

struct CaptureTime {
    let timeStamp: Int64
    let timeScale: Int32
}

extension CaptureTime {
    init() {
        self.init(timeStamp: 0, timeScale: 0)
    }
    
    init(_ time: CMTime) {
        timeStamp = time.value
        timeScale = time.timescale
    }
    
    var cmTime: CMTime {
        return CMTime(value: timeStamp, timescale: timeScale, flags: [.valid, .hasBeenRounded], epoch: 0)
    }
    
    var seconds: Double {
        return CMTimeGetSeconds(cmTime)
    }
    
    func substract(_ time: CaptureTime) -> CaptureTime {
        if timeScale == time.timeScale {
            return CaptureTime(timeStamp: timeStamp - time.timeStamp, timeScale: timeScale)
        }
        else {
            return CaptureTime(timeStamp: timeStamp * Int64(time.timeScale) - time.timeStamp * Int64(timeScale),
                               timeScale: timeScale * time.timeScale)
        }
    }
}
