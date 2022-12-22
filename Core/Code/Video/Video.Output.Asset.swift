//
//  Video.Input.File.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 30.04.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation
import CoreImage


extension Video {
    class AssetOutput : Capture.AssetOutput, Video.Processor.Proto {
        init(asset: AVAssetWriter, assetSession: Capture.AssetWriterSession, settings: CaptureSettings) {
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings.data)
            super.init(writer: asset, writerSession: assetSession, input: input)
        }
        
        init(asset: AVAssetWriter, assetSession: Capture.AssetWriterSession, input: AVAssetWriterInput) {
            super.init(writer: asset, writerSession: assetSession, input: input)
        }
        
        func process(video: Video.Sample) {
            process(sampleBuffer: video.sampleBuffer)
        }
    }
}
