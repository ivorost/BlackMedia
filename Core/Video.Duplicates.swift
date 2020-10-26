//
//  Video.Duplicates.swift
//  Capture
//
//  Created by Ivan Kh on 27.10.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation

class VideoRemoveDuplicateFrames : VideoOutputProxy {
    private var lastImageBuffer: CVImageBuffer?
    
    override func process(video: CMSampleBuffer) {
        let imageBuffer = CMSampleBufferGetImageBuffer(video)
        
        guard lastImageBuffer != imageBuffer else { return }

        super.process(video: video)
        lastImageBuffer = imageBuffer
    }
}
