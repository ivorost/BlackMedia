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
                 inputFPS: FuncWithDouble?,
                 outputFPS: FuncWithDouble?) throws -> SessionProtocol {

        var sessions = [SessionProtocol]()

        // Capture
        
        let avCaptureSession = AVCaptureSession()
        avCaptureSession.sessionPreset = .high

        // Displays

        var displayInputs = [DisplayInput]()
        var displayOutputs = [VideoCaptureSession]()

        for displayConfig in config.displays {
            let dimensions = CMVideoDimensions(width: Int32(displayConfig.rect.width),
                                               height: Int32(displayConfig.rect.height))

            // Output
            
            var output = [VideoOutputProtocol]()

            let preview = VideoOutputLayer(layer)

            let h264deserializer = VideoH264Deserializer(preview)
            
            let h264serializer = VideoH264Serializer(h264deserializer)

            let h264encoder = VideoEncoderSessionH264(inputDimension: dimensions,
                                                      outputDimentions: dimensions,
                                                      next: h264serializer)

            output.append(h264encoder)

            #if DEBUG
            if let fps = outputFPS {
//                output.append(VideoFPS(MeasureFPSPrint(title: "fps (duplicates)", callback: fps)))
                output.append(VideoFPS(MeasureFPS(callback: fps)))
            }
            #endif
            
            // Capture
            
            var removeDuplicatesMeasure: MeasureProtocol?
            
            #if DEBUG
//            removeDuplicatesMeasure = MeasureDurationAveragePrint(title: "duration (duplicates)")
            #endif

            var capture: VideoOutputProtocol = VideoRemoveDuplicateFrames(next: broadcast(output),
                                                                          measure: removeDuplicatesMeasure)
            
            #if DEBUG
            if let fps = inputFPS {
//                capture = VideoFPS(next: capture, measure: MeasureFPSPrint(title: "fps (input)", callback: fps))
                capture = VideoFPS(next: capture, measure: MeasureFPS(callback: fps))
            }
            #endif

            let captureSession = VideoCaptureSession(session: avCaptureSession,
                                                     queue: Capture.shared.captureQueue,
                                                     output: capture)
            
            let input = DisplayInput(session: avCaptureSession,
                                     display: displayConfig,
                                     video: config.video)

            // Setup
            
            displayInputs.append(input)
            displayOutputs.append(captureSession)
            sessions.append(preview)
            sessions.append(h264encoder)
        }

        let displayInput = broadcast(displayInputs)
        let displayOutput = broadcast(displayOutputs)

        // Size monitoring
        
        if let displayOutput = displayOutput { sessions.append(displayOutput) }
        if let displayInput = displayInput { sessions.append(displayInput) }
        sessions.append(avCaptureSession)

        return SessionSyncDispatch(session: SessionBroadcast(sessions), queue: Capture.shared.captureQueue)
    }

}
