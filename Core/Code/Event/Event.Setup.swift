//
//  Event.Setup.swift
//  Capture
//
//  Created by Ivan Kh on 23.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AppKit


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


public protocol EventProcessorSetupProtocol : CaptureSetupProtocol {
    func event(_ event: EventProcessor.Proto, kind: EventProcessor.Kind) -> EventProcessor.Proto
}


public extension EventProcessor {
    typealias Setup = EventProcessorSetupProtocol
}


public class EventProcessorSetup : EventProcessor.Setup {
    public static let shared = EventProcessorSetup()
    
    public func event(_ event: EventProcessor.Proto, kind: EventProcessor.Kind) -> EventProcessor.Proto {
        return event
    }
    
    public func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        return data
    }

    public func session(_ session: SessionProtocol, kind: Session.Kind) {
    }
    
    public func complete() -> SessionProtocol? {
        return nil
    }
}


public extension EventProcessorSetup {
    typealias Base = EventProcessorSetup
    typealias Proto = EventProcessorSetupProtocol
}


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


extension EventProcessorSetup {
    open class Vector : CaptureSetup.VectorBase<Proto>, Proto {
        public func event(_ event: EventProcessor.Proto, kind: EventProcessor.Kind) -> EventProcessor.Proto {
            return vector.reduce(event) { $1.event($0, kind: kind) }
        }
    }
}

    
public extension EventProcessorSetup {
    class Default : Slave {
        private let targetKind: EventProcessor.Kind
        private let selfKind: EventProcessor.Kind
        private let create: (EventProcessor.Proto) -> EventProcessor.Proto
        
        init(root: EventProcessor.Setup,
             targetKind: EventProcessor.Kind,
             selfKind: EventProcessor.Kind,
             create: @escaping (EventProcessor.Proto) -> EventProcessor.Proto) {
            
            self.targetKind = targetKind
            self.selfKind = selfKind
            self.create = create
            super.init(root: root)
        }
        
        public override func event(_ event: EventProcessor.Proto, kind: EventProcessor.Kind) -> EventProcessor.Proto {
            var result = event
            
            if kind == targetKind {
                result = root.event(create(result), kind: selfKind)
            }
            
            return super.event(result, kind: kind)
        }
    }
}
 

extension EventProcessorSetup {
   fileprivate class SessionAdapter : Base {
        private let session: Session.Setup
        
        init(session: Session.Setup) {
            self.session = session
        }

        override func session(_ session: SessionProtocol, kind: Session.Kind) {
            self.session.session(session, kind: kind)
        }
        
        override func complete() -> SessionProtocol? {
            return self.session.complete()
        }
    }
}
    

extension EventProcessorSetup {
    fileprivate class CaptureAdapter : SessionAdapter {
        private let capture: CaptureSetup.Proto
        
        init(capture: CaptureSetup.Proto) {
            self.capture = capture
            super.init(session: capture)
        }
        
        override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
            return capture.data(data, kind: kind)
        }
    }
}


public extension EventProcessorSetup {
    class DispatchAsync : Default {
        public init(root: EventProcessor.Setup, queue: DispatchQueue) {
            super.init(root: root, targetKind: .capture, selfKind: .other) {
                return EventProcessor.DispatchAsync(next: $0, queue: queue)
            }
        }
    }
}


public extension EventProcessor.DispatchAsync {
    typealias Setup = EventProcessorSetup.DispatchAsync
}


public extension EventProcessorSetup {
    class Checkbox : CheckboxChain<Proto>, Proto {
        public init(next: EventProcessorSetup.Proto, checkbox: NSButton) {
            super.init(next: next, checkbox: checkbox, off: EventProcessorSetup.shared)
        }
        
        public func event(_ event: EventProcessor.Proto, kind: EventProcessor.Kind) -> EventProcessor.Proto {
            return next.event(event, kind: kind)
        }
        
        public func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
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


public func cast(event session: Session.Setup) -> EventProcessor.Setup {
    return EventProcessorSetup.SessionAdapter(session: session)
}


public func cast(event capture: Capture.Setup) -> EventProcessor.Setup {
    return EventProcessorSetup.CaptureAdapter(capture: capture)
}
