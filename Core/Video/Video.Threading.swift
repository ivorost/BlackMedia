//
//  Video.Threading.swift
//  Capture
//
//  Created by Ivan Kh on 18.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation


class VideoSetupMultithreading : VideoSetupSlave {
    override func video(_ video: VideoOutputProtocol, kind: VideoOutputKind) -> VideoOutputProtocol {
        var result = video
        
        if kind == .encoder {
            result = VideoOutputDispatch(next: result, queue: Capture.shared.outputQueue)
        }
        
        return super.video(result, kind: kind)
    }
}
