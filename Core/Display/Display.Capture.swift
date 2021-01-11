//
//  Screen.Capture.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 22.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//


import AVFoundation


class DisplayCapture {
    
}


class DisplaySetup : VideoSetupSlave {
    private let settings: DisplayConfig
    private let avCaptureSession = AVCaptureSession()
    
    init(root: VideoSetupProtocol, settings: DisplayConfig) {
        self.settings = settings
        super.init(root: root)
    }
    
    override func session(_ session: Session.Proto, kind: Session.Kind) {
        if kind == .initial {
            let video = root.video(VideoProcessor(), kind: .capture)
            
            setupSession(avCaptureSession)
            root.session(input(), kind: .input)
            root.session(capture(next: video), kind: .capture)
            root.session(avCaptureSession, kind: .avCapture)
        }
    }
    
    func input() -> DisplayInput {
        return DisplayInput(session: avCaptureSession,
                            settings: settings)
    }
    
    func capture(next: VideoOutputProtocol) -> VideoCaptureSession {
        return VideoCaptureSession(session: avCaptureSession,
                                   queue: Capture.shared.captureQueue,
                                   output: next)
    }
    
    func setupSession(_ session: AVCaptureSession) {
        session.sessionPreset = .high
    }
}


extension Capture {

    func display(config: (display: DisplayConfig, video: VideoConfig),
                 inputFPS: FuncWithDouble?,
                 outputFPS: FuncWithDouble?,
                 layer: AVSampleBufferDisplayLayer?) throws -> SessionProtocol {

        var sessions = [SessionProtocol]()
        let duration = MeasureDurationAveragePrint(title: "duration")

        // Capture
        
        let avCaptureSession = AVCaptureSession()
        avCaptureSession.sessionPreset = .high

        // Displays

        let dimensions = CMVideoDimensions(width: Int32(config.display.rect.width),
                                           height: Int32(config.display.rect.height))
        
        // Output
        
        let qualityTuner = DataProcessor()
        
        var dataOutput = [DataProcessorProtocol]()
        
        var output = [VideoOutputProtocol]()
        
        let webSocketOutput = WebSocketMaster(name: "machine_mac", next: qualityTuner)
  
//        let measureByterate = MeasureByteratePrint(title: "byterate", next: webSocketOutput, callback: {_ in })

        dataOutput.append(webSocketOutput)
        
        if let layer = layer {
            let preview = VideoOutputLayer(layer)
            let h264deserializer = VideoH264Deserializer(next: preview)
            
            dataOutput.append(h264deserializer)
        }
        
        let h264serializer = VideoH264Serializer(next: broadcast(dataOutput) ?? DataProcessor.shared)

        let durationEnd = VideoProcessor(next: h264serializer, measure: MeasureEnd(duration))

        let h264encoder = VideoEncoderSessionH264(inputDimension: dimensions,
                                                  outputDimentions: dimensions,
                                                  next: durationEnd)
        
        let h264encoderSync = VideoOutputDispatch(next: h264encoder,
                                                  queue: Capture.shared.outputQueue)
        
        output.append(h264encoderSync)
        
        if let fps = outputFPS {
            output.append(VideoFPS(MeasureFPSPrint(title: "fps (duplicates)", callback: fps)))
//            output.append(VideoFPS(MeasureFPS(callback: fps)))
        }
        
        // Capture
        
//        var removeDuplicatesMeasure: MeasureProtocol?
//        
//        #if DEBUG
//        removeDuplicatesMeasure = MeasureDurationAveragePrint(title: "duration (duplicates)")
//        #endif
        
        var capture: VideoOutputProtocol = broadcast(output) ?? VideoProcessor()
        
        capture = VideoRemoveDuplicateFramesUsingMetal(next: capture)

//        let videoQuality = VideoSenderACK/*VideoQualityTuner*/(next: capture)
//        capture = videoQuality
//        qualityTuner.nextWeak = videoQuality

        if let fps = inputFPS {
            //                capture = VideoFPS(next: capture, measure: MeasureFPSPrint(title: "fps (input)", callback: fps))
            capture = VideoFPS(next: capture, measure: MeasureFPS(callback: fps))
        }
        
//        capture = MeasureVideo(measure: MeasureDurationPrint(title: "--- total"), next: capture)
        
        capture = VideoProcessor(next: capture, measure: MeasureBegin(duration))
        
        let captureSession = VideoCaptureSession(session: avCaptureSession,
                                                 queue: Capture.shared.captureQueue,
                                                 output: capture)
        
        let input = DisplayInput(session: avCaptureSession,
                                 settings: config.display)
        
        // Setup
        
        sessions.append(webSocketOutput)
        sessions.append(h264encoder)
        sessions.append(captureSession)
        sessions.append(input)
        sessions.append(avCaptureSession)

        return Session.DispatchSync(session: Session.Broadcast(sessions), queue: Capture.shared.captureQueue)
    }

}
