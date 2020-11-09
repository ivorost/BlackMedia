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
                       queue: Capture.shared.captureQueue,
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
        let videoOutput = VideoCaptureSession(session: captureSession,
                                              queue: Capture.shared.captureQueue,
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
        return SessionSyncDispatch(session: SessionBroadcast(sessions), queue: Capture.shared.captureQueue)
    }
    
    func preview(preview layer: AVSampleBufferDisplayLayer,
                 inputFPS: FuncWithDouble?) -> SessionProtocol {
        
        let server = DataProcessorImpl()
        var sessions = [SessionProtocol]()
        let preview = VideoOutputLayer(layer)
        let quality = VideoQuality(server: server, next: preview)
        let h264deserializer = VideoH264Deserializer(quality)
        let webSocket = WebSocketInput(h264deserializer)

        server.nextWeak = webSocket
        sessions.append(preview)
        sessions.append(webSocket)

        return SessionSyncDispatch(session: SessionBroadcast(sessions), queue: Capture.shared.outputQueue)
    }
}
