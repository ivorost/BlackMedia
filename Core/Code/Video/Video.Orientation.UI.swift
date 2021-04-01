//
//  Video.Orientation.UI.swift
//  Capture
//
//  Created by Ivan Kh on 31.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation

public extension VideoProcessor {
    class LayerOrientation : Base {
        private let layer: SampleBufferDisplayLayer
        private var x = false
        
        public init(next: VideoProcessor.Proto, layer: SampleBufferDisplayLayer) {
            self.layer = layer
            super.init(next: next)
        }
        
        public override func process(video: VideoBuffer) {
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


public extension VideoSetup {
    class LayerOrientation : VideoSetupProcessor {
        public init(layer: SampleBufferDisplayLayer, kind: VideoProcessor.Kind = .preview) {
            super.init(kind: kind) {
                VideoProcessor.LayerOrientation(next: $0, layer: layer)
            }
        }
    }
}
