//
//  Audio.General.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 08.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation


protocol AudioOutputProtocol {
    
    func process(audio: CMSampleBuffer)
}


class AudioOutputProxy : AudioOutputProtocol {
    
    var target: AudioOutputProtocol?
    
    init(_ target: AudioOutputProtocol? = nil) {
        self.target = target
    }
    
    func process(audio: CMSampleBuffer) {
        target?.process(audio: audio)
    }
}


extension CaptureSettings {
    static func audio(config: AudioConfig) -> CaptureSettings {
        var acl = AudioChannelLayout()
        bzero(&acl, MemoryLayout.size(ofValue: acl))
        acl.mChannelLayoutTag = config.channelLayout
        
        let result: [String:Any] = [
            AVFormatIDKey : config.codec,
            AVNumberOfChannelsKey : config.channelsNumber,
            AVSampleRateKey : config.sampleRate,
            AVChannelLayoutKey : Data(bytes: &acl, count: MemoryLayout<AudioChannelLayout>.size),
            AVEncoderBitRateKey : Double(config.bitRate)
        ]

        return CaptureSettings(result)
    }
}


struct AudioConfig {
    let codec: AudioFormatID
    let channelLayout: AudioChannelLayoutTag
    let channelsNumber: Int
    let sampleRate: Int
    let bitRate: Int
}
