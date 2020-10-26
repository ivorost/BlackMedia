//
//  Audio.Output.Asset.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 08.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation

class AudioAssetOutput : AssetOutput, AudioOutputProtocol {
    
    init(asset: AVAssetWriter, assetSession: AssetWriterSession, settings: CaptureSettings) {
        let input = AVAssetWriterInput(mediaType: .audio, outputSettings: settings.data)
        super.init(writer: asset, writerSession: assetSession, input: input)
    }
    
    func process(audio: CMSampleBuffer) {
        process(sampleBuffer: audio)
    }
}
