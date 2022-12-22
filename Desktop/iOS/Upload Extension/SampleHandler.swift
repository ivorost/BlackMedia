//
//  SampleHandler.swift
//  CaptureIOS Upload Extension
//
//  Created by Ivan Kh on 17.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import ReplayKit


class SampleHandler: RPBroadcastSampleHandler {

    private var session: Session.Proto?
    private var config: Video.Setup.ScreenCapture?
    private var videoID: UInt = 0
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        let dimensions = CMVideoDimensions(width: Int32(UIScreen.main.bounds.width * UIScreen.main.scale),
                                           height: Int32(UIScreen.main.bounds.height * UIScreen.main.scale))
        let encoderConfig = Video.EncoderConfig(codec: .h264,
                                                input: dimensions,
                                                output: dimensions)
        let config = Video.Setup.ScreenCapture(encoderConfig: encoderConfig)

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
                        
            Capture.queue.async {
                self.config?.capture?.video.process(video: Video.Sample(ID: videoID, buffer: sampleBuffer))
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
