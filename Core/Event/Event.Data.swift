//
//  Event.Data.swift
//  Capture
//
//  Created by Ivan Kh on 23.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AppKit


extension EventProcessor {
    class Serializer : Proto {
        private let next: DataProcessorProtocol
        
        init(next: DataProcessorProtocol) {
            self.next = next
        }
        
        func process(event: NSEvent) {
            let packet: PacketSerializer
            
            if let cgEvent = event.cgEvent, let data = NSData(cgEvent: cgEvent) {
                packet = PacketSerializer(.cgevent)
                packet.push(data: data)
            }
            else {
                let encoder = NSKeyedArchiver()
                encoder.outputFormat = .xml
                event.encode(with: encoder)
                encoder.finishEncoding()
                
                packet = PacketSerializer(.nsevent)
                packet.push(data: encoder.encodedData)
            }
            
            next.process(data: packet.data)
        }
    }
}


extension EventProcessorSetup {
    class Serializer : Slave {
        override func event(_ event: EventProcessor.Proto, kind: EventProcessor.Kind) -> EventProcessor.Proto {
            var result = event
            
            if kind == .capture {
                let serializerData = root.data(DataProcessor(), kind: .serializer)
                let serializer = root.event(EventProcessor.Serializer(next: serializerData), kind: .serializer)
                result = EventProcessor.Chain(prev: result, next: serializer)
            }
            
            return result
        }
    }
}


extension EventProcessor.Serializer {
    typealias Setup = EventProcessorSetup.Serializer
}


extension EventProcessor {
    class Deserializer : DataProcessorProtocol {
        private let next: Proto
        
        init(next: Proto) {
            self.next = next
        }
        
        func process(data: Data) {
            let packet = PacketDeserializer(data)
            var event: NSEvent?
            let eventData = packet.popData()
            
            if packet.type == .nsevent {
                let decoder = NSKeyedUnarchiver(forReadingWith: eventData)
                event = NSEvent(coder: decoder)
                assert(event != nil)
            }
            
            if packet.type == .cgevent {
                if let cgEvent = CGEvent(withDataAllocator: nil, data: eventData as CFData) {
                    event = NSEvent(cgEvent: cgEvent)
                }
                assert(event != nil)
            }
            
            if let event = event {
                next.process(event: event)
            }
        }
    }
}


extension EventProcessorSetup {
    class Deserializer : Slave {
        private let target: DataProcessor.Kind
        
        init(root: Proto, target: DataProcessor.Kind = .networkDataOutput) {
            self.target = target
            super.init(root: root)
        }
        
        override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
            var result = data
            
            if kind == self.target {
                let event = root.event(EventProcessor.shared, kind: .deserializer)
                let deserializer = root.data(EventProcessor.Deserializer(next: event), kind: .deserializer)
                result = deserializer
            }
            
            return super.data(result, kind: kind)
        }
    }
}


extension EventProcessor.Deserializer {
    typealias Setup = EventProcessorSetup.Deserializer
}
