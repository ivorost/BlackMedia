//
//  VideoOutput.swift
//  Chat
//
//  Created by Ivan Khvorostinin on 06/06/2017.
//  Copyright © 2017 ys1382. All rights reserved.
//

import AVFoundation

class VideoOutputLayer : VideoOutputProtocol, SessionProtocol {
    
    let layer: AVSampleBufferDisplayLayer
    var format: CMFormatDescription?
    
    init(_ layer: AVSampleBufferDisplayLayer) {
        self.layer = layer
    }
    
    func printStatus() {
        if layer.status == .failed {
            logAVError("AVQueuedSampleBufferRenderingStatus failed")
        }
        if let error = layer.error {
            logAVError(error.localizedDescription)
        }
        if !layer.isReadyForMoreMediaData {
            logAVError("Video layer not ready for more media data")
        }
    }

    func start() throws {
        logAVPrior("video output start")
        layer.flushAndRemoveImage()
    }
    
    func stop() {
        logAVPrior("video output stop")
        layer.flushAndRemoveImage()
    }
    
    func process(video: CMSampleBuffer) {
        logAV("video output \(video.presentationSeconds)")

        let dataFormat = CMSampleBufferGetFormatDescription(video)
        
        if CMFormatDescriptionEqual(format, otherFormatDescription: dataFormat) == false {
            layer.flush()
        }
        
        format = dataFormat
        
        dispatch_sync_on_main {
            if self.layer.isReadyForMoreMediaData && self.layer.status != .failed {
                self.layer.enqueue(video)
            }
            else {
                self.printStatus()
                self.layer.flush()
            }
        }
    }
}
