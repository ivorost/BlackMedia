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
    static func streamCamera<TNetwork>(input avInput: AVCaptureDeviceInput,
                                       format: AVCaptureDevice.Format,
                                       to network: TNetwork,
                                       preview layer: AVSampleBufferDisplayLayer) -> Session.Proto
    where TNetwork: Data.Producer.TheProto & Data.Processor.TheProto {
        let session = Capture.Session()
        let input = Capture.Input(session: session.inner, input: avInput)
        let videoOutput = Output(inner: .video32BGRA(session.inner))
        let encoderConfig = Video.EncoderConfig(codec: .h264, format: format)
        let preview = Video.Processor.Display(layer)
        let duplicates = Video.RemoveDuplicatesApproxUsingMetal()
        let encoder = Video.Processor.EncoderH264(inputDimension: encoderConfig.input,
                                                  outputDimentions: encoderConfig.output)
        let serializer = Processor.SerializerH264()

//        let ackHot = Video.Acknowledge.StageHot()
//        let ackCold = Video.Acknowledge.StageCold(ackHot)
//        let ackHandler = Network.Acknowledge.Handler(hot: ackHot, cold: ackCold)

        videoOutput
            .next(preview)
//            .next(ackCold)
            .next(duplicates)
            .next(encoder)
//            .next(ackHot)
            .next(serializer)
            .next(network)

//        network
//            .next(ackHandler)
        
        return broadcast([ encoder, input, videoOutput, session ])
    }

    static func streamCamera<TNetwork>(to network: TNetwork,
                                       preview layer: AVSampleBufferDisplayLayer) -> Session.Proto
    where TNetwork: Data.Producer.TheProto & Data.Processor.TheProto {
        guard let avInput = AVCaptureDeviceInput.rearCamera else { return Session.shared }

        return streamCamera(input: avInput,
                            format: avInput.device.activeFormat,
                            to: network,
                            preview: layer)
    }

    static func display<TNetwork>(from network: TNetwork, to layer: AVSampleBufferDisplayLayer) -> Session.Proto
    where TNetwork: Data.Producer.TheProto & Data.Processor.TheProto {
        let deserializer = Data.Processor.DeserializerH264()
        let preview = Video.Processor.Display(layer)
//        let acknowledge = Network.Acknowledge.Answer(network: network)

        network
//            .next(acknowledge)
            .next(deserializer)
            .next(preview)

        return Session.shared
    }
}

