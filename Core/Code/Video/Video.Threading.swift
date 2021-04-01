//
//  Video.Threading.swift
//  Capture
//
//  Created by Ivan Kh on 18.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation


public class VideoSetupMultithreading : VideoSetupSlave {
    private let queue: OperationQueue
    
    public init(root: VideoSetupProtocol, queue: OperationQueue) {
        self.queue = queue
        super.init(root: root)
    }
    
    public override func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        var result = video
        
        if kind == .encoder {
            result = VideoOutputDispatch(next: result, queue: queue)
        }
        
        return super.video(result, kind: kind)
    }
}
