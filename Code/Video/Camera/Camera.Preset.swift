//
//  Camera.Preset.swift
//  Core
//
//  Created by Ivan Kh on 07.04.2022.
//

import AVFoundation
import BlackUtils

@available(iOSApplicationExtension, unavailable)
public extension Video {
    static func streamCamera(input avInput: AVCaptureDeviceInput,
                             format: AVCaptureDevice.Format,
                             layer: AVSampleBufferDisplayLayer,
                             network: Data.Processor.AnyProto) -> Session.Proto {
        let avCaptureSession = AVCaptureSession()
        let input = Capture.Input(session: avCaptureSession, input: avInput)
        let videoOutput = Output(inner: .video32BGRA(avCaptureSession))
        let encoderConfig = Video.EncoderConfig(codec: .h264, format: format)
        let preview = Video.Processor.Display(layer)
        let duplicates = Video.RemoveDuplicatesApproxUsingMetal()
        let encoder = Video.Processor.EncoderH264(inputDimension: encoderConfig.input,
                                                  outputDimentions: encoderConfig.output)
        let serializer = Processor.SerializerH264()

        videoOutput
            .next(preview)
            .next(duplicates)
            .next(encoder)
            .next(serializer)
            .next(network)
        
        return broadcast([ encoder, input, videoOutput, avCaptureSession ])
    }
}

@available(iOSApplicationExtension, unavailable)
public extension Video.Setup {
    class CameraCapture : Vector {
        private let encoderOutputQueue = OperationQueue()
        private let layer: SampleBufferDisplayLayer
        private let network: Data.Processor.AnyProto
        
        public init(layer: SampleBufferDisplayLayer, network: Data.Processor.AnyProto) {
            self.encoderOutputQueue.maxConcurrentOperationCount = 1
            self.layer = layer
            self.network = network
            
            super.init()
        }
        
        public override func create() -> [Proto] {
            let root = self

            guard let avInput = AVCaptureDeviceInput.nannyCamera else { return [] }
            let format = avInput.device.nannyFormat
            let input = DeviceInput.rearCamera(root: root, input: avInput, format: format)
            let encoderConfig = Video.EncoderConfig(codec: .h264, format: format)
            
            let aggregator = Session.Setup.Aggregator()
            let preview = Display(root: root, layer: layer, kind: .duplicatesFree)
            let duplicates = DuplicatesApproxMetal(root: root)
            let encoder = EncoderH264(root: root, settings: encoderConfig)
            let serializer = SerializerH264(root: root, kind: .encoder)
            let network = Network.Setup.Put(root: root, data: self.network, target: .serializer)

            // Measure
            let fps = MeasureFPS(next: String.Processor.Print("fps: "))
            let fpsSetup = Measure(kind: .duplicatesFree, measure: fps)

            // Flush periodically
            let flushPeriodically = Flushable.Periodically(next: Flushable.Vector([ fps ]))
            let flushPeriodicallyDispatch = Session.DispatchSync(session: flushPeriodically, queue: DispatchQueue.main)
            let flushPeriodicallySetup = Session.Setup.Static(root: root, session: flushPeriodicallyDispatch)

            return [
                cast(video: network),
                cast(video: aggregator),
                encoder,
                duplicates,
                serializer,
                preview,
                input,
                fpsSetup,
                cast(video: flushPeriodicallySetup) ]
        }
    }
}
