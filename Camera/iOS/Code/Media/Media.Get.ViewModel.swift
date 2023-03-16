//
//  Media.Get.ViewModel.swift
//  Camera
//
//  Created by Ivan Kh on 11.12.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import Foundation

extension Media {
    struct Get {}
}


extension Media.Get {
    class ViewModel : Media.ViewModel {
        var selector: any Peer.Selector.Proto

        init(_ selector: any Peer.Selector.Proto) {
            self.selector = selector
        }
        
        override func setup(layer: SampleBufferDisplayLayer) -> Video.Setup.Proto {
            let root = Video.Setup.get(layer: layer)
            let network = Peer.Get.Setup(selector: selector,
                                         root: root,
                                         session: .networkData,
                                         target: .deserializer,
                                         network: .networkData,
                                         output: .networkDataOutput)
            
            root.prepend(cast(video: network))
            return root
        }
    }
}
