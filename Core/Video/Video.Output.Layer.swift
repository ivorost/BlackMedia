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
        
        dispatch_sync_on_main {
            if CMFormatDescriptionEqual(format, otherFormatDescription: dataFormat) == false {
                layer.flush()
            }
            
            format = dataFormat

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


class VideoSetupPreview : VideoSetupSlave {
    let layer: AVSampleBufferDisplayLayer
    
    init(root: VideoSetupProtocol, layer: AVSampleBufferDisplayLayer) {
        self.layer = layer
        super.init(root: root)
    }
        
    override func video(_ video: VideoOutputProtocol, kind: VideoOutputKind) -> VideoOutputProtocol {
        var result = video
        
        if kind == .deserializer {
            let previous = result
            result = root.video(VideoOutputLayer(layer), kind: .preview)
            result = VideoOutputImpl(prev: previous, next: result)
        }
        
        return super.video(result, kind: kind)
    }
}
