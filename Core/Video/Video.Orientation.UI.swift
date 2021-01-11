//
//  Video.Orientation.UI.swift
//  Capture
//
//  Created by Ivan Kh on 31.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation

extension VideoProcessor {
    class LayerOrientation : Base {
        private let layer: SampleBufferDisplayLayer
        private var x = false
        
        init(next: VideoProcessor.Proto, layer: SampleBufferDisplayLayer) {
            self.layer = layer
            super.init(next: next)
        }
        
        override func process(video: VideoBuffer) {
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


extension VideoSetup {
    class LayerOrientation : VideoSetupProcessor {
        init(layer: SampleBufferDisplayLayer, kind: VideoProcessor.Kind = .preview) {
            super.init(kind: kind) {
                VideoProcessor.LayerOrientation(next: $0, layer: layer)
            }
        }
    }
}
