//
//  Camera.Preset.swift
//  Core
//
//  Created by Ivan Kh on 07.04.2022.
//

import AVFoundation


public extension Video.Setup {
    class CameraCapture : Vector {
        private let encoderOutputQueue = OperationQueue()
        private let layer: AVSampleBufferDisplayLayer
        private let network: Data.Processor.Proto
        
        public init(layer: AVSampleBufferDisplayLayer, network: Data.Processor.Proto) {
            self.encoderOutputQueue.maxConcurrentOperationCount = 1
            self.layer = layer
            self.network = network
            
            super.init()
        }
        
        public override func create() -> [Proto] {
            let root = self

            guard let avInput = try? AVCaptureDeviceInput.nannyCamera() else { assertionFailure(); return [] }
            let format = avInput.device.nannyFormat
            let input = DeviceInput.rearCamera(root: root, input: avInput, format: format)
            let encoderConfig = Video.EncoderConfig(codec: .h264, format: format)
            
            let aggregator = Session.Setup.Aggregator()
            let preview = Display(root: root, layer: layer, kind: .capture)
            let orientation = Orientation()
            let encoder = Encoder(root: root, settings: encoderConfig)
            let serializer = SerializerH264(root: root, kind: .encoder)
            let network = Network.Setup.Put(root: root, data: self.network, target: .serializer)

            // Measure
            let fps = MeasureFPS()
            let fpsSetup = Measure(kind: .capture, measure: fps)

            // Flush periodically
            let flushPeriodically = Flushable.Periodically(next: Flushable.Vector([ fps ]))
            let flushPeriodicallyDispatch = Session.DispatchSync(session: flushPeriodically, queue: DispatchQueue.main)
            let flushPeriodicallySetup = Session.Setup.Static(root: root, session: flushPeriodicallyDispatch)

            return [
                cast(video: network),
                cast(video: aggregator),
                encoder,
                serializer,
                preview,
                input,
                orientation,
                fpsSetup,
                cast(video: flushPeriodicallySetup) ]
        }
    }
}
