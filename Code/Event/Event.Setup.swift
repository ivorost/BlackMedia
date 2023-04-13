//
//  Event.Setup.swift
//  Capture
//
//  Created by Ivan Kh on 23.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

#if canImport(AppKit)
import AppKit
#endif


#if canImport(AppKit)
public extension EventProcessor.Kind {
    static let other = EventProcessor.Kind(rawValue: "other")
    static let capture = EventProcessor.Kind(rawValue: "capture")
    static let post = EventProcessor.Kind(rawValue: "post")
    static let filterTypes = EventProcessor.Kind(rawValue: "filterTypes")
    static let filterWindow = EventProcessor.Kind(rawValue: "filterWindow")
    static let filterMouseMove = EventProcessor.Kind(rawValue: "filterMouseMove")
    static let transform = EventProcessor.Kind(rawValue: "transform")
    static let serializer = EventProcessor.Kind(rawValue: "serializer")
    static let deserializer = EventProcessor.Kind(rawValue: "deserializer")
}
#endif


#if canImport(AppKit)
public protocol EventProcessorSetupProtocol : Capture.Setup.Proto {
    func event(_ event: EventProcessor.AnyProto, kind: EventProcessor.Kind) -> EventProcessor.AnyProto
}
#endif


#if canImport(AppKit)
public extension EventProcessor {
    typealias Setup = EventProcessorSetupProtocol
}
#endif


#if canImport(AppKit)
public class EventProcessorSetup : EventProcessor.Setup {
    public static let shared = EventProcessorSetup()
    
    public func event(_ event: EventProcessor.AnyProto, kind: EventProcessor.Kind) -> EventProcessor.AnyProto {
        return event
    }
    
    public func data(_ data: Data.Processor.AnyProto, kind: Data.Processor.Kind) -> Data.Processor.AnyProto {
        return data
    }

    public func session(_ session: Session.Proto, kind: Session.Kind) {
    }
    
    public func complete() -> Session.Proto? {
        return nil
    }
}
#endif


#if canImport(AppKit)
public extension EventProcessorSetup {
    typealias Base = EventProcessorSetup
    typealias Proto = EventProcessorSetupProtocol
}
#endif


#if canImport(AppKit)
public extension EventProcessorSetup {
    class Slave : Base {
        private(set) weak var _root: Proto?
        
        public init(root: Proto) {
            self._root = root
        }
        
        var root: Proto {
            return _root ?? Base.shared
        }
    }
}
#endif


#if canImport(AppKit)
extension EventProcessorSetup {
    open class Vector : Capture.Setup.VectorBase<Proto>, Proto {
        public func event(_ event: EventProcessor.AnyProto, kind: EventProcessor.Kind) -> EventProcessor.AnyProto {
            var result: EventProcessor.AnyProto = EventProcessor.shared

            for i in vector {
                result = i.event(result, kind: kind)
            }

            return result
        }
    }
}
#endif

    
#if canImport(AppKit)
public extension EventProcessorSetup {
    class Default : Slave {
        private let targetKind: EventProcessor.Kind
        private let selfKind: EventProcessor.Kind
        private let create: (EventProcessor.AnyProto) -> EventProcessor.AnyProto
        
        init(root: EventProcessor.Setup,
             targetKind: EventProcessor.Kind,
             selfKind: EventProcessor.Kind,
             create: @escaping (EventProcessor.AnyProto) -> EventProcessor.AnyProto) {
            
            self.targetKind = targetKind
            self.selfKind = selfKind
            self.create = create
            super.init(root: root)
        }
        
        public override func event(_ event: EventProcessor.AnyProto, kind: EventProcessor.Kind) -> EventProcessor.AnyProto {
            var result = event
            
            if kind == targetKind {
                result = root.event(create(result), kind: selfKind)
            }
            
            return super.event(result, kind: kind)
        }
    }
}
#endif


#if canImport(AppKit)
extension EventProcessorSetup {
   fileprivate class SessionAdapter : Base {
        private let session: Session.Setup.Proto
        
        init(session: Session.Setup.Proto) {
            self.session = session
        }

        override func session(_ session: Session.Proto, kind: Session.Kind) {
            self.session.session(session, kind: kind)
        }
        
        override func complete() -> Session.Proto? {
            return self.session.complete()
        }
    }
}
#endif


#if canImport(AppKit)
extension EventProcessorSetup {
    fileprivate class CaptureAdapter : SessionAdapter {
        private let capture: Capture.Setup.Proto
        
        init(capture: Capture.Setup.Proto) {
            self.capture = capture
            super.init(session: capture)
        }
        
        override func data(_ data: Data.Processor.AnyProto, kind: Data.Processor.Kind) -> Data.Processor.AnyProto {
            return capture.data(data, kind: kind)
        }
    }
}
#endif


#if canImport(AppKit)
public extension EventProcessorSetup {
    class DispatchAsync : Default {
        public init(root: EventProcessor.Setup, queue: DispatchQueue) {
            super.init(root: root, targetKind: .capture, selfKind: .other) {
                return EventProcessor.DispatchAsync(next: $0, queue: queue)
            }
        }
    }
}
#endif


#if canImport(AppKit)
public extension EventProcessor.DispatchAsync {
    typealias Setup = EventProcessorSetup.DispatchAsync
}
#endif


#if canImport(AppKit)
public extension EventProcessorSetup {
    class Checkbox : CheckboxChain<Proto>, Proto {
        public init(next: EventProcessorSetup.Proto, checkbox: NSButton) {
            super.init(next: next, checkbox: checkbox, off: EventProcessorSetup.shared)
        }
        
        public func event(_ event: EventProcessor.AnyProto, kind: EventProcessor.Kind) -> EventProcessor.AnyProto {
            return next.event(event, kind: kind)
        }
        
        public func data(_ data: Data.Processor.AnyProto, kind: Data.Processor.Kind) -> Data.Processor.AnyProto {
            return next.data(data, kind: kind)
        }
        
        public func session(_ session: Session.Proto, kind: Session.Kind) {
            next.session(session, kind: kind)
        }
        
        public func complete() -> Session.Proto? {
            next.complete()
        }
    }
}
#endif


#if canImport(AppKit)
public func cast(event session: Session.Setup.Proto) -> EventProcessor.Setup {
    return EventProcessorSetup.SessionAdapter(session: session)
}
#endif


#if canImport(AppKit)
public func cast(event capture: Capture.Setup.Proto) -> EventProcessor.Setup {
    return EventProcessorSetup.CaptureAdapter(capture: capture)
}
#endif
