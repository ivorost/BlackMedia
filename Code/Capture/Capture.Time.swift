//
//  AV.Time.swift
//  Capture
//
//  Created by Ivan Kh on 02.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation
import BlackUtils

public extension Capture {
    struct Time {
        let timeStamp: Int64
        let timeScale: Int32
    }
}

extension Capture.Time: BinaryCodable {
    public init(from data: inout Data) throws {
        self.init(timeStamp: try data.pop(Int64.self),
                  timeScale: try data.pop(Int32.self))
    }

    public func encode(to data: inout Data) -> Int {
        data.encode(timeStamp)
        + data.encode(timeScale)
    }
}

extension Capture.Time {
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
    
    func substract(_ time: Capture.Time) -> Capture.Time {
        if timeScale == time.timeScale {
            return Capture.Time(timeStamp: timeStamp - time.timeStamp, timeScale: timeScale)
        }
        else {
            return Capture.Time(timeStamp: timeStamp * Int64(time.timeScale) - time.timeStamp * Int64(timeScale),
                                timeScale: timeScale * time.timeScale)
        }
    }
}
