//
//  Listen.Segue.swift
//  CaptureIOS Upload Extension
//
//  Created by Ivan Kh on 21.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import UIKit
import AVFoundation

fileprivate class SetupVideoListening : VideoSetupVector {
    private let layer: SampleBufferDisplayLayer

    init(layer: SampleBufferDisplayLayer) {
        self.layer = layer
        super.init()
    }
    
    override func create() -> [VideoSetupProtocol] {
        guard
            let wsReceiverData = URL.wsReceiverData,
            let wsReceiverHelm = URL.wsReceiverHelm
        else { assert(false); return [] }

        let root = self
        let preview = VideoSetupPreview(root: root, layer: layer, kind: .deserializer)
        let orientation = VideoSetup.LayerOrientation(layer: layer)
        let deserializer = VideoSetupDeserializerH264(root: root, kind: .networkDataOutput)
        let webSocketHelm = WebSocketClient.Setup(helm: root, url: wsReceiverHelm, target: .serializer)
        let webSocketACK = VideoSetupViewerACK(root: root)
        let aggregator = SessionSetup.Aggregator()
        let websocket = WebSocketClient.Setup(data: self, url: wsReceiverData, target: .serializer)

        return [
            cast(video: websocket),
            cast(video: aggregator),
            preview,
            orientation,
            deserializer,
//            decoder,
            cast(video: webSocketHelm),
            webSocketACK ]
    }
}

class ListenSegue : UIStoryboardSegue {
    override func perform() {
        super.perform()
        
        guard let listenController = self.destination as? ListenViewController else { assert(false); return }
        _ = listenController.view
        
        let setup = SetupVideoListening(layer: listenController.sampleBufferView.sampleLayer)
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
