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
    
    func process(video: VideoBuffer) {
        logAV("video output \(video.sampleBuffer.presentationSeconds)")

        let dataFormat = CMSampleBufferGetFormatDescription(video.sampleBuffer)
        
        dispatch_sync_on_main {
            if CMFormatDescriptionEqual(format, otherFormatDescription: dataFormat) == false {
                layer.flush()
            }
            
            format = dataFormat

            if self.layer.isReadyForMoreMediaData && self.layer.status != .failed {
                self.layer.enqueue(video.sampleBuffer)
            }
            else {
                self.printStatus()
                self.layer.flush()
            }
        }
    }
}


class VideoSetupPreview : VideoSetupSlave {
    private let layer: AVSampleBufferDisplayLayer
    private let kind: VideoProcessor.Kind
    
    init(root: VideoSetupProtocol, layer: AVSampleBufferDisplayLayer, kind: VideoProcessor.Kind) {
        self.layer = layer
        self.kind = kind
        super.init(root: root)
    }
        
    override func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        var result = video
        
        if kind == self.kind {
            let previous = result
            result = root.video(VideoOutputLayer(layer), kind: .preview)
            result = VideoProcessor(prev: previous, next: result)
        }
        
        return super.video(result, kind: kind)
    }
}
