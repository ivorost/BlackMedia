//
//  SampleHandler.swift
//  CaptureIOS Upload Extension
//
//  Created by Ivan Kh on 17.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import ReplayKit


fileprivate class SetupDisplayCapture : VideoSetupVector {
    private let encoderConfig: VideoEncoderConfig
    private(set) var capture: VideoSetup.External?
    
    init(encoderConfig: VideoEncoderConfig) {
        self.encoderConfig = encoderConfig
        super.init()
    }
    
    override func create() -> [VideoSetupProtocol] {
        let root = self
        let aggregator = SessionSetup.Aggregator()
        let timebase = Timebase(); root.session(timebase, kind: .other)
        let displayInfo = DisplaySetup.InfoCapture(root: root, settings: DisplayConfig(displayID: 0, fps: CMTime.zero)!)
        let capture = VideoSetup.External(root: root)
        let orientation = VideoSetup.Orientation()
        let encoder = VideoSetupEncoder(root: root, settings: encoderConfig)
        let multithreading = VideoSetupMultithreading(root: root)
        let websocket = WebSocketMaster.SetupData(root: self, target: .serializer)
        let webSocketHelm = cast(video: WebSocketMaster.SetupHelm(root: root, target: .none))
        let webSocketACK = VideoSetupSenderACK(root: root, timebase: timebase, metric: StringProcessor.Print.shared)
        
        let byterateString = StringProcessor.shared//.Print.shared
        let byterateMeasure = MeasureByterate(string: byterateString)
        let byterate = VideoSetupDataProcessor(data: byterateMeasure, kind: .networkDataOutput)

        let flushPeriodically = Flushable.Periodically(next: Flushable.Vector([ /*byterateMeasure*/ ]))
        aggregator.session(Session.DispatchSync(session: flushPeriodically, queue: DispatchQueue.main), kind: .other)

        self.capture = capture
        
        return [
            cast(video: websocket),
            cast(video: displayInfo),
            cast(video: aggregator),
            encoder,
            multithreading,
            webSocketHelm,
            webSocketACK,
            cast(video: capture),
            orientation,
            byterate ]
    }
}


class SampleHandler: RPBroadcastSampleHandler {

    private var session: Session.Proto?
    private var config: SetupDisplayCapture?
    private var videoID: UInt = 0
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        let dimensions = CMVideoDimensions(width: Int32(UIScreen.main.bounds.width * UIScreen.main.scale),
                                           height: Int32(UIScreen.main.bounds.height * UIScreen.main.scale))
        let encoderConfig = VideoEncoderConfig(codec: .h264,
                                               input: dimensions,
                                               output: dimensions)
        let config = SetupDisplayCapture(encoderConfig: encoderConfig)

        self.videoID = 0
        self.config = config
        self.session = config.setup()
        try! self.session?.start()
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        session?.stop()
        session = nil
        config = nil
        videoID = 0
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            self.videoID += 1
            let videoID = self.videoID
                        
            Capture.shared.captureQueue.async {
                self.config?.capture?.video.process(video: VideoBuffer(ID: videoID, buffer: sampleBuffer))
            }
            assert(config?.capture != nil)
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
}
