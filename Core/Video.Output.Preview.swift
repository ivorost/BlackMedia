//
//  Video.Output.Preview.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 30.04.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation

class VideoPreview : VideoSession {
    
    let layer: AVCaptureVideoPreviewLayer
    let session: AVCaptureSession
    
    convenience init(_ layer: AVCaptureVideoPreviewLayer,
                     _ session: AVCaptureSession) {
        self.init(layer, session, nil)
    }

    init(_ layer: AVCaptureVideoPreviewLayer,
         _ session: AVCaptureSession,
         _ next: VideoSessionProtocol?) {
        self.layer = layer
        self.session = session
        super.init(next)
    }

    override func start() throws {
        logAVPrior("video preview start")

        dispatch_sync_on_main {
            layer.session = session
            layer.connection?.automaticallyAdjustsVideoMirroring = false
            layer.connection?.isVideoMirrored = false
        }

        try super.start()
    }
    
    override func stop() {
        logAVPrior("video preview stop")

        super.stop()
        
        dispatch_sync_on_main {
            layer.session = nil
        }
    }
}
