//
//  Video.Orientation.swift
//  Capture
//
//  Created by Ivan Kh on 29.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation
#if os(iOS)
import ReplayKit
#endif


#if os(iOS)
extension VideoProcessor {
    class Orientation : Base {
        override func process(video: VideoBuffer) {
            let orientation = CMGetAttachment(video.sampleBuffer,
                                              key: RPVideoSampleOrientationKey as CFString,
                                              attachmentModeOut: nil)

            let orientationVal: CGImagePropertyOrientation? = CGImagePropertyOrientation(rawValue: orientation!.uint32Value)
            
            if let orientation = orientation {
                super.process(video: video.copy(orientation: orientation.uint8Value))
            }
            else {
                assert(false)
                super.process(video: video)
            }
        }
    }
}
#endif


#if os(iOS)
extension VideoSetup {
    class Orientation : VideoSetupProcessor {
        init(kind: VideoProcessor.Kind = .capture) {
            super.init(kind: kind) {
                return VideoProcessor.Orientation(next: $0)
            }
        }
    }
}
#endif
