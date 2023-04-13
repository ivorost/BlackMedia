//
//  Global.RemoteDesktop.swift
//  Core
//
//  Created by Ivan Kh on 08.04.2022.
//

import AVFoundation
import BlackUtils

public final class RemoteDesktop {
    public final class Setup {}
}


#if os(OSX)
public extension RemoteDesktop.Setup {
    class Sender : Capture.Setup.Vector {
        private let displayConfig: Video.ScreenConfig
        private let encoderConfig: Video.EncoderConfig
        private let views: Video.ScreenCaptureViews
        private let layer: AVSampleBufferDisplayLayer
        private let videoRoot = Video.Setup.Vector()
        private let eventRoot = EventProcessorSetup.Vector()
        private let url: URL
        
        public init(url: URL,
                    displayConfig: Video.ScreenConfig,
                    encoderConfig: Video.EncoderConfig,
                    views: Video.ScreenCaptureViews,
                    layer: AVSampleBufferDisplayLayer) {
            self.url = url
            self.displayConfig = displayConfig
            self.encoderConfig = encoderConfig
            self.views = views
            self.layer = layer
            super.init()
        }
        
        public override func create() -> [Capture.Setup.Proto] {
            let websocket = Network.Setup.WebSocket(data: self, url: url, target: .serializer)
            let aggregator = Session.Setup.Aggregator()
            let aggregatorDispatch = Session.Setup.DispatchSync(next: aggregator, queue: Capture.Setup.queue)
            
            videoRoot.append(cast(video: websocket))
            videoRoot.append(cast(video: aggregator))
            
            eventRoot.append(cast(event: websocket))
            eventRoot.append(cast(event: aggregator))
            
            var screen: Video.Setup.Proto = Video.Setup.ScreenCapture(root: videoRoot,
                                                                      url: url,
                                                                      displayConfig: displayConfig,
                                                                      encoderConfig: encoderConfig,
                                                                      view: views,
                                                                      layer: layer)
            var events: EventProcessor.Setup = Event.Setup.Receiver(root: eventRoot)
            
            screen = Video.Setup.Checkbox(next: screen, checkbox: views.setupDisplayButton)
            events = EventProcessorSetup.Checkbox(next: events, checkbox: views.setupEventsButton)
            
            videoRoot.append(screen)
            eventRoot.append(events)
            
            return [websocket, screen, events, cast(capture: aggregatorDispatch)]
        }
    }
}
#endif


#if os(OSX)
public extension RemoteDesktop.Setup {
    class Receiver : Capture.Setup.Vector {
        private let views: Video.ScreenCaptureViews
        private let layer: SampleBufferDisplayLayer
        private let videoRoot = Video.Setup.Vector()
        private let eventRoot = EventProcessorSetup.Vector()
        private let url: URL
        
        public init(url: URL, views: Video.ScreenCaptureViews, layer: SampleBufferDisplayLayer) {
            self.url = url
            self.views = views
            self.layer = layer
            super.init()
        }
        
        public override func create() -> [Capture.Setup.Proto] {
            let aggregator = Session.Setup.Aggregator()
            let aggregatorDispatch = Session.Setup.DispatchSync(next: aggregator, queue: Capture.Setup.queue)
            let websocket = Network.Setup.WebSocket(data: self, url: url, target: .serializer)
            
            videoRoot.append(cast(video: websocket))
            videoRoot.append(cast(video: aggregator))
            eventRoot.append(cast(event: websocket))
            eventRoot.append(cast(event: aggregator))
            
            var video: Video.Setup.Proto = Video.Setup.Receiver(root: videoRoot, url: url, view: views, layer: layer)
            var events: EventProcessor.Setup = Event.Setup.Sender(root: eventRoot, layer: layer)
            
            video = Video.Setup.Checkbox(next: video, checkbox: views.setupDisplayButton)
            events = EventProcessorSetup.Checkbox(next: events, checkbox: views.setupEventsButton)
            
            videoRoot.append(video)
            eventRoot.append(events)
            
            return [websocket, video, events, cast(capture: aggregatorDispatch)]
        }
    }
}
#endif
