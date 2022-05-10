//
//  Listen.Segue.swift
//  CaptureIOS Upload Extension
//
//  Created by Ivan Kh on 21.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import UIKit
import AVFoundation


class ListenSegue : UIStoryboardSegue {
    override func perform() {
        super.perform()
        
        guard let listenController = self.destination as? ListenViewController else { assert(false); return }
        _ = listenController.view
        
        let setup = Video.Setup.get(websocket: .wsSenderData!, layer: listenController.sampleBufferView.sampleLayer)
        let session = setup.setup()
        
        listenController.sampleBufferView.sampleLayer.videoGravity = .resizeAspect
        
        do {
            try session?.start()
            listenController.session = session
        }
        catch {
            logAVError(error)
        }
    }
}
