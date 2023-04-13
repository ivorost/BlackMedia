//
//  VideoOutput.swift
//  Chat
//
//  Created by Ivan Khvorostinin on 06/06/2017.
//  Copyright © 2017 ys1382. All rights reserved.
//

import AVFoundation
import BlackUtils


public extension Video.Processor {
    class Display {

        let layer: AVSampleBufferDisplayLayer
        var format: CMFormatDescription?
        
        public init(_ layer: AVSampleBufferDisplayLayer) {
            self.layer = layer
        }
        
        private func printStatus() {
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
    }
}


extension Video.Processor.Display : ProcessorProtocol {
    public func process(_ video: Video.Sample) {
        logAV("video output \(video.sampleBuffer.presentationSeconds)")
        
        let dataFormat = CMSampleBufferGetFormatDescription(video.sampleBuffer)
        
        if CMFormatDescriptionEqual(format, otherFormatDescription: dataFormat) == false {
            layer.flush()
        }
        
        format = dataFormat
        
        if self.layer.status != .failed {
            self.layer.enqueue(video.sampleBuffer)
        }
        else {
            self.printStatus()
            self.layer.flush()
        }
    }
}


extension Video.Processor.Display : Session.Proto {
    public func start() throws {
        logAVPrior("video output start")
        layer.flushAndRemoveImage()
    }
    
    public func stop() {
        logAVPrior("video output stop")
        layer.flushAndRemoveImage()
    }
}


public extension Video {
    class Display {
        
        private let layer: AVCaptureVideoPreviewLayer
        private let session: AVCaptureSession
        
        init(_ layer: AVCaptureVideoPreviewLayer,
             _ session: AVCaptureSession) {
            self.layer = layer
            self.session = session
        }
    }
}


extension Video.Display : Session.Proto {
    public func start() throws {
        logAVPrior("video preview start")

        dispatch_sync_on_main {
            layer.session = session
            layer.connection?.automaticallyAdjustsVideoMirroring = false
            layer.connection?.isVideoMirrored = false
        }
    }
    
    public func stop() {
        logAVPrior("video preview stop")

        dispatch_sync_on_main {
            layer.session = nil
        }
    }
}


public extension Video.Setup {
    class Display : Video.Setup.Slave {
        private let layer: AVSampleBufferDisplayLayer
        private let kind: Video.Processor.Kind
        
        public init(root: Video.Setup.Proto, layer: AVSampleBufferDisplayLayer, kind: Video.Processor.Kind) {
            self.layer = layer
            self.kind = kind
            super.init(root: root)
        }
        
        public override func video(_ video: Video.Processor.AnyProto, kind: Video.Processor.Kind) -> Video.Processor.AnyProto {
            var result = video
            
            if kind == self.kind {
                let previous = result
                result = root.video(Video.Processor.Display(layer), kind: .preview)
                result = Video.Processor.Base(prev: previous, next: result)
            }
            
            return super.video(result, kind: kind)
        }
    }
}
