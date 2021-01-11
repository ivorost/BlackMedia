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
    
    func display(config: (display: DisplayConfig, video: VideoConfig),
                 inputFPS: FuncWithDouble?,
                 outputFPS: FuncWithDouble?,
                 layer: AVSampleBufferDisplayLayer) throws -> SessionProtocol {

        var sessions = [SessionProtocol]()

        // Capture
        
        let avCaptureSession = AVCaptureSession()
        avCaptureSession.sessionPreset = .high

        // Displays

        var displayInputs = [DisplayInput]()
        var displayOutputs = [VideoCaptureSession]()

        let dimensions = CMVideoDimensions(width: Int32(config.display.rect.width),
                                           height: Int32(config.display.rect.height))
        
        // Output
        
        var output = [VideoOutputProtocol]()
        
        let webSocketOutput = WebSocketOutput()
  
        let measureByterate = MeasureByteratePrint(title: "byterate", next: webSocketOutput, callback: {_ in })
//        let preview = VideoOutputLayer(layer)
//        let h264deserializer = VideoH264Deserializer(preview)

        let h264serializer = VideoH264Serializer(measureByterate)
        
        let h264encoder = VideoEncoderSessionH264(inputDimension: dimensions,
                                                  outputDimentions: dimensions,
                                                  next: h264serializer)
        
        output.append(h264encoder)
        
        if let fps = outputFPS {
            //                output.append(VideoFPS(MeasureFPSPrint(title: "fps (duplicates)", callback: fps)))
            output.append(VideoFPS(MeasureFPS(callback: fps)))
        }
        
        // Capture
        
        var removeDuplicatesMeasure: MeasureProtocol?
        
        #if DEBUG
        //            removeDuplicatesMeasure = MeasureDurationAveragePrint(title: "duration (duplicates)")
        #endif

//        var capture = broadcast(output)
        var capture: VideoOutputProtocol = VideoRemoveDuplicateFrames(next: broadcast(output),
                                                                      measure: removeDuplicatesMeasure)
        
        if let fps = inputFPS {
            //                capture = VideoFPS(next: capture, measure: MeasureFPSPrint(title: "fps (input)", callback: fps))
            capture = VideoFPS(next: capture, measure: MeasureFPS(callback: fps))
        }
        
//        capture = MeasureVideo(measure: MeasureDurationPrint(title: "--- total"), next: capture)
        
        let captureSession = VideoCaptureSession(session: avCaptureSession,
                                                 queue: Capture.shared.captureQueue,
                                                 output: capture)
        
        let input = DisplayInput(session: avCaptureSession,
                                 display: config.display,
                                 video: config.video)
        
        // Setup
        
        displayInputs.append(input)
        displayOutputs.append(captureSession)
        sessions.append(webSocketOutput)
        sessions.append(h264encoder)

        let displayInput = broadcast(displayInputs)
        let displayOutput = broadcast(displayOutputs)

        // Size monitoring
        
        if let displayOutput = displayOutput { sessions.append(displayOutput) }
        if let displayInput = displayInput { sessions.append(displayInput) }
        sessions.append(avCaptureSession)

        return SessionSyncDispatch(session: SessionBroadcast(sessions), queue: Capture.shared.captureQueue)
    }

}
