//
//  Media.Get.ViewModel.swift
//  Camera
//
//  Created by Ivan Kh on 04.11.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import Foundation


extension Media {
    struct Put {}
}


extension Media.Put {
    class ViewModel : Media.ViewModel {
        var selector: Peer.Selector

        init(_ selector: Peer.Selector) {
            self.selector = selector
        }
        
        override func setup(layer: SampleBufferDisplayLayer) -> Video.Setup.Proto {
            return Video.Setup.CameraCapture(layer: layer, network: Peer.Put(selector))
        }
    }
}
