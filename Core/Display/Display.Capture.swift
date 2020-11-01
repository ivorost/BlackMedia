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
                 preview layer: AVSampleBufferDisplayLayer,
                 output url: URL,
                 progress: inout CaptureProgress?,
                 inputFPS: FuncWithDouble?,
                 outputFPS: FuncWithDouble?) throws -> SessionProtocol {

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
        var displayOutputs = [VideoCaptureSession]()

        for displayConfig in config.displays {
            let input = DisplayInput(session: captureSession,
                                     display: displayConfig,
                                     video: config.video)
            let assetOutput = VideoAssetOutputPositioned(asset: assetWriter,
                                                         assetSession: assetWriterSession,
                                                         settings: videoSettings,
                                                         videoSize: config.video.dimensions.size,
                                                         assetRect: displayConfig.rect)

            let preview = VideoOutputLayer(layer)
            var output: VideoOutputProtocol = preview

//            output = VideoH264Serializer(next: nil)
//            
//            let dimensions = CMVideoDimensions(width: 1920, height: 1080)
//            let encoderH264 = VideoEncoderSessionH264(inputDimension: dimensions, outputDimentions: dimensions, next: output)
//            
//            sessions.append(encoderH264)
//            output = encoderH264
            
            if let fps = outputFPS {
                output = VideoFPS(next: output, measure: MeasureFPSPrint(title: "fps (duplicates)", callback: fps))
            }
            
            output = VideoRemoveDuplicateFrames(next: output,
                                                measure: MeasureDurationAveragePrint(title: "duration (duplicates)"))
            
            if let fps = inputFPS {
                output = VideoFPS(next: output, measure: MeasureFPSPrint(title: "fps (input)", callback: fps))
            }

            let videoOutput = VideoCaptureSession(session: captureSession,
                                                  queue: Capture.shared.captureQueue,
                                                  output: output)
            
            displayInputs.append(input)
            displayAssetOutputs.append(assetOutput)
            displayOutputs.append(videoOutput)
            sessions.append(preview)
        }

        let displayInput = broadcast(displayInputs)
        let displayOutput = broadcast(displayOutputs)
        let displayAssetOutput = broadcast(displayAssetOutputs)

        // Size monitoring
        
        let sizeMonitorSession = SizeMonitorSession(url: url, interval: 1)
        
        // flush each 10 second
        assetWriter.movieFragmentInterval = CMTime(seconds: 10, preferredTimescale: .prefferedVideoTimescale)

        if let displayOutput = displayOutput { sessions.append(displayOutput) }
        if let displayAssetOutput = displayAssetOutput { sessions.append(displayAssetOutput) }
        sessions.append(assetWriterSession)
        if let displayInput = displayInput { sessions.append(displayInput) }
        sessions.append(sizeMonitorSession)
        sessions.append(captureSession)

        progress = sizeMonitorSession
        return SessionSyncDispatch(session: SessionBroadcast(sessions), queue: Capture.shared.captureQueue)
    }

}
