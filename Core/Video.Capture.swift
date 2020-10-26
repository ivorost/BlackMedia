//
//  Video.Capture.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 22.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation

extension Capture {
    func video(config: CaptureConfig,
               preview layer: AVCaptureVideoPreviewLayer,
               output url: URL,
               progress: inout CaptureProgress?) throws -> SessionProtocol {
        
        var sessions = [SessionProtocol]()
        let audioOutputProxy = AudioOutputProxy()
        let audioSettings = CaptureSettings.audio(config: config.audioConfig)
        let videoSettings = CaptureSettings.video(config: config.videoConfig)

        // Input
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .low

        // Audio Input
        
        let audioInput =
            AudioInput(session: captureSession,
                       device: config.audioDevice,
                       queue: Capture.shared.queue,
                       output: audioOutputProxy)

        // Video Input

        let videoInput =
            VideoInput(session: captureSession,
                       device: config.videoDevice,
                       format: config.videoFormat)

        // Preview

        let preview = VideoPreview(layer, captureSession)
        
        // Output
        
        let assetWriter = try AVAssetWriter(url: url,
                                            fileType: config.fileType)
        let assetWriterSession = AssetWriterSession(asset: assetWriter)
        let audioAssetOutput = AudioAssetOutput(asset: assetWriter,
                                                assetSession: assetWriterSession,
                                                settings: audioSettings)
        let videoAssetOutput = VideoAssetOutput(asset: assetWriter,
                                                assetSession: assetWriterSession,
                                                settings: videoSettings)
        let videoOutput = VideoOutput(session: captureSession,
                                      queue: Capture.shared.queue,
                                      output: videoAssetOutput)

        audioOutputProxy.target = audioAssetOutput

        // Size monitoring
        
        let sizeMonitorSession = SizeMonitorSession(url: url, interval: 1)
        
        // flush each 10 second
        assetWriter.movieFragmentInterval = CMTime(seconds: 10, preferredTimescale: .prefferedVideoTimescale)

        sessions.append(videoOutput)
        sessions.append(audioAssetOutput)
        sessions.append(videoAssetOutput)
        sessions.append(assetWriterSession)
        sessions.append(preview)
        sessions.append(audioInput)
        sessions.append(videoInput)
        sessions.append(sizeMonitorSession)
        sessions.append(captureSession)

        progress = sizeMonitorSession
        return SessionSyncDispatch(session: SessionBroadcast(sessions), queue: Capture.shared.queue)
    }
}
