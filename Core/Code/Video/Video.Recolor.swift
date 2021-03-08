//
//  Video.Recolor.swift
//  Capture
//
//  Created by Ivan Kh on 19.01.2021.
//  Copyright © 2021 Ivan Kh. All rights reserved.
//

import AVFoundation
import CoreVideo
import CoreImage

// For convertion from sample.comp.hlsl to sample.comp.metal use:
// glslangValidator -e main -o sample.comp.spv -H -V -D sample.comp.hlsl
// spirv-cross sample.comp.spv --output sample.comp.metal --msl

public extension VideoProcessor {
    class Recolor : Base {
        private let lock = NSLock()
        private let metalProcessor: MetalProcessor.PixelBuffer?

        public required init(next: VideoOutputProtocol) {
            do {
                let url = Bundle.this.url(forResource: "default", withExtension: "metallib")!
                metalProcessor = try MetalProcessor.PixelBuffer(library: url, function: "main0")
            }
            catch {
                metalProcessor = nil
                logAVError(error)
            }
   
            super.init(next: next)
        }
        
        public override func process(video: VideoBuffer) {
            lock.locked {
                if let imageBuffer = CMSampleBufferGetImageBuffer(video.sampleBuffer) {
                    process(pixelBuffer1: imageBuffer, pixelBuffer2: imageBuffer)
                }
            }
            
            super.process(video: video)
        }
        
        private func process(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) {
            do {
                try metalProcessor?.processAndWait(pixelBuffer1: pixelBuffer1, pixelBuffer2: pixelBuffer2)
            }
            catch {
                logAVError(error)
            }
            
            return
        }

    }
}


public extension VideoSetup {
    class Recolor : VideoSetupProcessor {
        public init(target: VideoProcessor.Kind = .capture) {
            super.init(kind: target) {
                return VideoProcessor.Recolor(next: $0)
            }
        }
    }
}
