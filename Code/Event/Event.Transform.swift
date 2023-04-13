//
//  Event.Transform.swift
//  Capture
//
//  Created by Ivan Kh on 30.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

#if canImport(AppKit)
import AppKit
#endif
import BlackUtils

#if canImport(AppKit)
public extension EventProcessor {
    class Transform : Base {
        fileprivate var next: AnyProto?
        private let layer: CALayer
        private let display = Data.Processor.ScreenConfigDeserializer()
        private(set) var data: Data.Processor.AnyProto = Data.Processor.shared
        
        public init(layer: CALayer) {
            self.layer = layer
            super.init()
            self.data = Data.Processor.Callback { [weak self] data in
                self?.process(data)
            }
        }
        
        public override func process(_ event: NSEvent) {
            update(event)
            next?.process(event)
        }
        
        public func process(_ data: Data) {
            display.process(data)
        }
        
        private func update(_ event: NSEvent) {
            guard let settings = display.settings,
                  let cgEvent = event.cgEvent,
                  cgEvent.isMouse
            else { return }
            
            let window = (layer.delegate as! NSView).window!
            var location = NSEvent.mouseLocation
            
            location = window.convertFromScreen(NSRect(origin: NSEvent.mouseLocation, size: CGSize.zero)).origin
            location = layer.convert(location, from: nil)

            var videoSize = layer.frame.size
            let widthScale = layer.frame.width / settings.rect.width
            let heightScale = layer.frame.height / settings.rect.height
            
            if widthScale > heightScale {
                videoSize.width = videoSize.height * settings.rect.width / settings.rect.height
            }
            else {
                videoSize.height = videoSize.width * settings.rect.height / settings.rect.width
            }
            
            let scale = settings.rect.width / videoSize.width

            location.x -= (layer.frame.width - videoSize.width) / 2.0
            location.x = settings.rect.origin.x + location.x * scale
            location.y += (layer.frame.height - videoSize.height) / 2.0
            location.y = layer.frame.height - location.y
            location.y = settings.rect.origin.y + location.y * scale
            location.x /= settings.scale
            location.y /= settings.scale
            
            cgEvent.location = location
         }
    }
}
#endif


#if canImport(AppKit)
public extension EventProcessorSetup {
    class Transform : Slave {
        private let processor: EventProcessor.Transform
        
        public init(root: EventProcessorSetup.Slave.Proto, layer: CALayer) {
            processor = EventProcessor.Transform(layer: layer)
            super.init(root: root)
        }
        
        public override func event(_ event: EventProcessor.AnyProto, kind: EventProcessor.Kind) -> EventProcessor.AnyProto {
            var result = event
            
            if kind == .capture {
                processor.next = result
                result = root.event(processor, kind: .transform)
            }
            
            return super.event(result, kind: kind)
        }
        
        public override func data(_ data: Data.Processor.AnyProto, kind: Data.Processor.Kind) -> Data.Processor.AnyProto {
            var result = data
            
            if kind == .networkDataOutput {
                result = Data.Processor.Base(prev: result, next: processor.data)
            }
            
            return super.data(result, kind: kind)
        }
    }
}
#endif


#if canImport(AppKit)
public extension EventProcessor.Transform {
    typealias Setup = EventProcessorSetup.Transform
}
#endif
