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


public extension Video.Processor {
    class Orientation : Base {
        public override func process(video: Video.Buffer) {
            #if os(iOS)
            let orientation = CMGetAttachment(video.sampleBuffer,
                                              key: RPVideoSampleOrientationKey as CFString,
                                              attachmentModeOut: nil)
            
            if let orientation = orientation {
                super.process(video: video.copy(orientation: orientation.uint8Value))
            }
            else {
                #if !targetEnvironment(macCatalyst)
//                assert(false)
                #endif
                super.process(video: video)
            }
            #else
            super.process(video: video)
            #endif
        }
    }
}


public extension Video.Setup {
    class Orientation : Video.Setup.Processor {
        public init(kind: Video.Processor.Kind = .capture) {
            super.init(kind: kind) {
                return Video.Processor.Orientation(next: $0)
            }
        }
    }
}
