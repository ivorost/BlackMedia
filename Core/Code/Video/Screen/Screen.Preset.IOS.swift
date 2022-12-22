//
//  Screen.Preset.IOS.swift
//  Core
//
//  Created by Ivan Kh on 08.04.2022.
//


#if os(iOS)
import UIKit
import CoreMedia
#endif


#if os(iOS)
public extension Video.Setup {
    class ScreenCapture : Vector {
        public private(set) var capture: External?
        private let encoderConfig: Video.EncoderConfig
        private let encoderOutputQueue = OperationQueue()
        
        public init(encoderConfig: Video.EncoderConfig) {
            self.encoderConfig = encoderConfig
            self.encoderOutputQueue.maxConcurrentOperationCount = 3
            super.init()
        }
        
        public override func create() -> [Proto] {
            guard
                let wsSenderData = URL.wsSenderData,
                let wsSenderHelm = URL.wsSenderData
            else { assert(false); return [] }
            
            let screenConfig = Video.ScreenConfig(displayID: 0, fps: CMTime.zero)!
            let root = self
            let aggregator = Session.Setup.Aggregator()
            let timebase = Capture.Timebase(); root.session(timebase, kind: .other)
            let displayInfo = Capture.Setup.ScreenConfigSerializer(root: root, settings: screenConfig)
            let capture = External(root: root)
            let orientation = Orientation()
            let recolor = Recolor()
            let encoder = EncoderH264(root: root, settings: encoderConfig)
            let serializer = DeserializerH264(root: root, kind: .serializer)
            let multithreading = Multithreading(root: root, kind: .encoder, queue: encoderOutputQueue)
            let websocket = Network.Setup.WebSocket(data: self, url: wsSenderData, target: .serializer)
            let webSocketHelm = cast(video: Network.Setup.WebSocket(helm: root, url: wsSenderHelm, target: .none))
            let webSocketACK = SenderACK(root: root, timebase: timebase, metric: String.Processor.Print.shared)
            
            let byterateString = String.Processor.shared//.Print.shared
            let byterateMeasure = MeasureByterate(string: byterateString)
            let byterate = DataProcessor(data: byterateMeasure, kind: .networkDataOutput)
            
            let flushPeriodically = Flushable.Periodically(next: Flushable.Vector([ /*byterateMeasure*/ ]))
            aggregator.session(Session.DispatchSync(session: flushPeriodically, queue: DispatchQueue.main), kind: .other)
            
            self.capture = capture
            
            return [
                cast(video: websocket),
                cast(video: displayInfo),
                cast(video: aggregator),
                encoder,
                serializer,
                recolor,
                multithreading,
                webSocketHelm,
                webSocketACK,
                cast(video: capture),
                orientation,
                byterate ]
        }
    }
}
#endif
