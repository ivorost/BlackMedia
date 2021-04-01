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
public extension VideoProcessor {
    class Orientation : Base {
        public override func process(video: VideoBuffer) {
            let orientation = CMGetAttachment(video.sampleBuffer,
                                              key: RPVideoSampleOrientationKey as CFString,
                                              attachmentModeOut: nil)
            
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
public extension VideoSetup {
    class Orientation : VideoSetupProcessor {
        public init(kind: VideoProcessor.Kind = .capture) {
            super.init(kind: kind) {
                return VideoProcessor.Orientation(next: $0)
            }
        }
    }
}
#endif
