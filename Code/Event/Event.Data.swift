//
//  Event.Data.swift
//  Capture
//
//  Created by Ivan Kh on 23.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

#if canImport(AppKit)
import AppKit
#endif
import BlackUtils

#if canImport(AppKit)
public extension EventProcessor {
    class Serializer : Network.PacketSerializer.Processor, Proto {
        public func process(_ event: NSEvent) {
            let packet: Network.PacketSerializer
            
            if let cgEvent = event.cgEvent, let data = cgEvent.data {
                packet = Network.PacketSerializer(.cgevent)
                packet.push(data: data)
            }
            else {
                let encoder = NSKeyedArchiver(requiringSecureCoding: false)
                encoder.outputFormat = .xml
                event.encode(with: encoder)
                encoder.finishEncoding()

                packet = Network.PacketSerializer(.nsevent)
                packet.push(data: encoder.encodedData)
            }

            process(packet: packet)
        }
    }
}
#endif

#if canImport(AppKit)
public extension EventProcessorSetup {
    class Serializer : Slave {
        public override func event(_ event: EventProcessor.AnyProto, kind: EventProcessor.Kind) -> EventProcessor.AnyProto {
            var result = event
            
            if kind == .capture {
                let serializerData = root.data(Data.Processor.shared, kind: .serializer)
                let serializer = root.event(EventProcessor.Serializer(next: serializerData), kind: .serializer)
                result = EventProcessor.Chain(prev: result, next: serializer)
            }
            
            return result
        }
    }
}
#endif

#if canImport(AppKit)
public extension EventProcessor.Serializer {
    typealias Setup = EventProcessorSetup.Serializer
}
#endif

#if canImport(AppKit)
public extension EventProcessor {
    class Deserializer : Network.PacketDeserializer.Processor {
        fileprivate let next: AnyProto
        
        public init(type: Network.PacketType, next: AnyProto) {
            self.next = next
            super.init(type: type)
        }
    }

    
    class DeserializerCGEvent : Deserializer {
        init(next: EventProcessor.AnyProto) {
            super.init(type: .cgevent, next: next)
        }
        
        override func process(packet: Network.PacketDeserializer) {
            var event: NSEvent?
            let eventData = packet.popData()
            
            if let cgEvent = CGEvent(withDataAllocator: nil, data: eventData as CFData) {
                event = NSEvent(cgEvent: cgEvent)
            }
            
            assert(event != nil)
            
            if let event = event {
                next.process(event)
            }
        }
    }

    
    class DeserializerNSEvent : Deserializer {
        init(next: EventProcessor.AnyProto) {
            super.init(type: .nsevent, next: next)
        }
        
        override func process(packet: Network.PacketDeserializer) {
            let eventData = packet.popData()
            guard let decoder = try? NSKeyedUnarchiver(forReadingFrom: eventData) else { assert(false); return }
            let event = NSEvent(coder: decoder)
            
            assert(event != nil)
            
            if let event = event {
                next.process(event)
            }
        }
    }
}
#endif

#if canImport(AppKit)
public extension EventProcessorSetup {
    class Deserializer : Slave {
        private let target: Data.Processor.Kind
        
        public init(root: Proto, target: Data.Processor.Kind = .networkDataOutput) {
            self.target = target
            super.init(root: root)
        }
        
        public override func data(_ data: Data.Processor.AnyProto, kind: Data.Processor.Kind) -> Data.Processor.AnyProto {
            var result = data
            
            if kind == self.target {
                let event = root.event(EventProcessor.shared, kind: .deserializer)
                let deserializer = Data.Processor.broadcast([EventProcessor.DeserializerCGEvent(next: event),
                                                             EventProcessor.DeserializerNSEvent(next: event) ])
            
                result = root.data(deserializer, kind: .deserializer)
            }
            
            return super.data(result, kind: kind)
        }
    }
}
#endif

#if canImport(AppKit)
public extension EventProcessor.Deserializer {
    typealias Setup = EventProcessorSetup.Deserializer
}
#endif
