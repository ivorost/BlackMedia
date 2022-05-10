//
//  Event.Data.swift
//  Capture
//
//  Created by Ivan Kh on 23.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AppKit

public extension EventProcessor {
    class Serializer : Network.PacketSerializer.Processor, Proto {
        public func process(event: NSEvent) {
            let packet: Network.PacketSerializer
            
            if let cgEvent = event.cgEvent, let data = NSData(cgEvent: cgEvent) {
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


public extension EventProcessorSetup {
    class Serializer : Slave {
        public override func event(_ event: EventProcessor.Proto, kind: EventProcessor.Kind) -> EventProcessor.Proto {
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


public extension EventProcessor.Serializer {
    typealias Setup = EventProcessorSetup.Serializer
}


public extension EventProcessor {
    class Deserializer : Network.PacketDeserializer.Processor {
        fileprivate let next: Proto
        
        public init(type: Network.PacketType, next: Proto) {
            self.next = next
            super.init(type: type)
        }
    }

    
    class DeserializerCGEvent : Deserializer {
        init(next: EventProcessor.Proto) {
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
                next.process(event: event)
            }
        }
    }

    
    class DeserializerNSEvent : Deserializer {
        init(next: EventProcessor.Proto) {
            super.init(type: .nsevent, next: next)
        }
        
        override func process(packet: Network.PacketDeserializer) {
            let eventData = packet.popData()
            guard let decoder = try? NSKeyedUnarchiver(forReadingFrom: eventData) else { assert(false); return }
            let event = NSEvent(coder: decoder)
            
            assert(event != nil)
            
            if let event = event {
                next.process(event: event)
            }
        }
    }
}


public extension EventProcessorSetup {
    class Deserializer : Slave {
        private let target: Data.Processor.Kind
        
        public init(root: Proto, target: Data.Processor.Kind = .networkDataOutput) {
            self.target = target
            super.init(root: root)
        }
        
        public override func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
            var result = data
            
            if kind == self.target {
                let event = root.event(EventProcessor.shared, kind: .deserializer)
                let deserializer = broadcast([EventProcessor.DeserializerCGEvent(next: event),
                                              EventProcessor.DeserializerNSEvent(next: event) ])
            
                if let deserializer = deserializer {
                    result = root.data(deserializer, kind: .deserializer)
                }
            }
            
            return super.data(result, kind: kind)
        }
    }
}


public extension EventProcessor.Deserializer {
    typealias Setup = EventProcessorSetup.Deserializer
}
