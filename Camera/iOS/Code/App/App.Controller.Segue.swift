//
//  App.Controller.Segue.swift
//  Camera
//
//  Created by Ivan Kh on 08.12.2021.
//  Copyright © 2021 Ivan Kh. All rights reserved.
//

import UIKit
import Utils
import Core

class PeerTraceShowSegue : ConcreteSegue<AppController, PeerTraceController> {
    override func perform(source: AppController, destination: PeerTraceController) {
        super.perform(source: source, destination: destination)
        
        destination.peers?.items = source.peersSubject
        destination.logs?.items = source.peersLog.items
    }
}


class MediaSegue<TDst> : ConcreteSegue<AppController, TDst> where TDst : MediaBaseController {
    override func perform(source: AppController, destination: TDst) {
        super.perform(source: source, destination: destination)

        _ = destination.view
        let sampleLayer = destination.sampleBufferView.sampleLayer

        Core.Capture.queue.async {
            let setup = self.setup(source: source, destination: destination, layer: sampleLayer)
            let session = setup.setup()

            do {
                try session?.start()
                destination.session = session
            }
            catch {
                logAVError(error)
            }
        }
    }
    
    func setup(source: AppController, destination: TDst, layer: SampleBufferDisplayLayer) -> Video.Setup.Proto {
        return Video.Setup.shared
    }
}


class CaptureSegue : MediaSegue<CaptureController> {
    override func setup(source: AppController,
                        destination: CaptureController,
                        layer: SampleBufferDisplayLayer) -> Video.Setup.Proto {

        return Video.Setup.CameraCapture(layer: layer, network: source.put)
    }
}


class ReceiverSegue : MediaSegue<ReceiverController> {
    override func setup(source: AppController,
                        destination: ReceiverController,
                        layer: SampleBufferDisplayLayer) -> Video.Setup.Proto {
        
        let root = Video.Setup.get(layer: layer)
        let network = Peer.Get.Setup(selector: source.peerSelector,
                                     root: root,
                                     session: .networkData,
                                     target: .deserializer,
                                     network: .networkData,
                                     output: .networkDataOutput)
        
        root.prepend(cast(video: network))
        return root
    }
}
