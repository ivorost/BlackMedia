//
//  Screen.Capture.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 22.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation
import AppKit

extension Capture {
    
    func display(config: (file: AVFileType, displays: [DisplayConfig], video: VideoConfig),
                 preview layer: AVCaptureVideoPreviewLayer,
                 output url: URL,
                 progress: inout CaptureProgress?,
                 fps: FuncWithDouble?) throws -> SessionProtocol {

        var sessions = [SessionProtocol]()
        let videoSettings = CaptureSettings.video(config: config.video)

        // Input
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high

        // Asset writer
        
        let assetWriter = try AVAssetWriter(url: url, fileType: config.file)
        let assetWriterSession = AssetWriterSession(asset: assetWriter)

        // Displays

        var displayInputs = [DisplayInput]()
        var displayAssetOutputs = [VideoAssetOutput]()
        var displayOutputs = [VideoOutput]()

        for displayConfig in config.displays {
            let input = DisplayInput(session: captureSession,
                                     display: displayConfig,
                                     video: config.video)
            let assetOutput = VideoAssetOutputPositioned(asset: assetWriter,
                                                         assetSession: assetWriterSession,
                                                         settings: videoSettings,
                                                         videoSize: config.video.dimensions.size,
                                                         assetRect: displayConfig.rect)
            var output: VideoOutputProtocol = assetOutput
            
            if let fps = fps {
                output = VideoFPS(callback: fps, target: output)
            }
            
            let videoOutput = VideoOutput(session: captureSession,
                                          queue: Capture.shared.queue,
                                          output: output)
            
            displayInputs.append(input)
            displayAssetOutputs.append(assetOutput)
            displayOutputs.append(videoOutput)
        }

        let displayInput = broadcast(displayInputs)
        let displayOutput = broadcast(displayOutputs)
        let displayAssetOutput = broadcast(displayAssetOutputs)

        // Output

        let preview = VideoPreview(layer, captureSession)

        // Size monitoring
        
        let sizeMonitorSession = SizeMonitorSession(url: url, interval: 1)
        
        // flush each 10 second
        assetWriter.movieFragmentInterval = CMTime(seconds: 10, preferredTimescale: .prefferedVideoTimescale)

        if let displayOutput = displayOutput { sessions.append(displayOutput) }
        if let displayAssetOutput = displayAssetOutput { sessions.append(displayAssetOutput) }
        sessions.append(assetWriterSession)
        sessions.append(preview)
        if let displayInput = displayInput { sessions.append(displayInput) }
        sessions.append(sizeMonitorSession)
        sessions.append(captureSession)

        progress = sizeMonitorSession
        return SessionSyncDispatch(session: SessionBroadcast(sessions), queue: Capture.shared.queue)
    }

}
