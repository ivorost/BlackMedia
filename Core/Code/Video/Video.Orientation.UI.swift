//
//  Video.Orientation.UI.swift
//  Capture
//
//  Created by Ivan Kh on 31.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation

public extension Video.Processor {
    class LayerOrientation : Base {
        private let layer: SampleBufferDisplayLayer
        private var x = false
        
        public init(next: Video.Processor.Proto, layer: SampleBufferDisplayLayer) {
            self.layer = layer
            super.init(next: next)
        }
        
        public override func process(video: Video.Buffer) {
            guard let orientation = video.orientation else {
                super.process(video: video)
                return
            }
            guard let rotation = SampleBufferDisplayLayer.Rotation(rawValue: orientation) else {
                super.process(video: video)
                return
            }
            
            guard let formatDescription = CMSampleBufferGetFormatDescription(video.sampleBuffer) else {
                assert(false); return
            }
            
            layer.setVideo(rotation: rotation, dimensions:CMVideoFormatDescriptionGetDimensions(formatDescription))
            super.process(video: video)
        }
    }
}


public extension Video.Setup {
    class LayerOrientation : Video.Setup.Processor {
        public init(layer: SampleBufferDisplayLayer, kind: Video.Processor.Kind = .preview) {
            super.init(kind: kind) {
                Video.Processor.LayerOrientation(next: $0, layer: layer)
            }
        }
    }
}
