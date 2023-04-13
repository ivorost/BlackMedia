//
//  Event.Preset.swift
//  Core
//
//  Created by Ivan Kh on 08.04.2022.
//

#if canImport(Cocoa)
import Cocoa
#endif

#if canImport(Cocoa)
public extension Event.Setup {
    class Sender : EventProcessorSetup.Vector {
        private let root: EventProcessor.Setup
        private let layer: CALayer
        
        public init(root: EventProcessor.Setup, layer: CALayer) {
            self.root = root
            self.layer = layer
            super.init()
        }
        
        public override func create() -> [EventProcessor.Setup] {
            let supportedTypes: NSEvent.EventTypeMask = [
                .keyUp,
                .keyDown,
                .flagsChanged,
                .scrollWheel,
                .mouseMoved,
                .rightMouseUp,
                .rightMouseDown,
                .rightMouseDragged,
                .leftMouseUp,
                .leftMouseDown,
                .leftMouseDragged,
                .otherMouseUp,
                .otherMouseDown,
                .otherMouseDragged ]
            
            let queueGet = DispatchQueue.createEventsGet()
            let transform = EventProcessor.Transform.Setup(root: root, layer: layer)
            let filter = EventProcessor.FilterByMask.Setup(root: root, supportedTypes: supportedTypes)
            var filterWindow: EventProcessor.Setup = EventProcessorSetup.shared
            let filterMouseMove = EventProcessorSetup.FilterMouseMove(root: root, queue: queueGet, interval: 1.0 / 30.0)
            var captureWindow = Session.Setup.shared
            
            let serializer = EventProcessor.Serializer.Setup(root: root)
            let dispatchCapture = EventProcessor.DispatchAsync.Setup(root: root, queue: queueGet)
            let capture = EventCapture.Setup(root: root)
            
            if let window = (layer.delegate as? NSView)?.window {
                filterWindow = EventProcessor.FilterByWindow.Setup(root: root, window: window)
                captureWindow = EventCapture.Window.Setup(root: root, window: window)
            }
            
            return [
                serializer,
                filter,
                filterWindow,
                filterMouseMove,
                capture,
                dispatchCapture,
                transform,
                cast(event: captureWindow) ]
        }
    }
}
#endif


#if canImport(Cocoa)
public extension Event.Setup {
    class Receiver : EventProcessorSetup.Vector {
        private let root: EventProcessor.Setup
        
        public init(root: EventProcessor.Setup) {
            self.root = root
            super.init()
        }
        
        public override func create() -> [EventProcessor.Setup] {
            let deserializer = EventProcessor.Deserializer.Setup(root: root)
            let post = EventProcessor.Post.Setup(root: root)
            
            return [
                deserializer,
                post ]
        }
    }
}
#endif
