//
//  AV.Setup.swift
//  Capture
//
//  Created by Ivan Kh on 23.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation


public protocol CaptureSetupProtocol : Session.Setup & DataProcessor.Setup {
}


public class CaptureSetup : CaptureSetupProtocol {
    static let shared = CaptureSetup()
    
    public func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        return data
    }
    
    public func session(_ session: Session.Proto, kind: Session.Kind) {
    }
    
    public func complete() -> Session.Proto? {
        return Session.shared
    }
}


public extension Capture {
    typealias Setup = CaptureSetupProtocol
}


extension CaptureSetup {
    public typealias Proto = CaptureSetupProtocol
    public typealias Base = CaptureSetup
}


public extension CaptureSetup {
    class Slave : Base {
        private(set) weak var _root: Proto?
        
        init(root: Proto) {
            self._root = root
        }
        
        var root: Proto {
            return _root ?? CaptureSetup.shared
        }
    }
}


extension CaptureSetup {
    open class VectorBase<T> : ProcessorWithVectorProtocol & Proto {
        private(set) var vector: [T]
        private var data = DataProcessorSetup.Vector([])
        private var session = SessionSetup.Vector([])

        public init() {
            vector = []
            vector = create()
            self.data = DataProcessorSetup.Vector(vector as! [Proto])
            self.session = SessionSetup.Vector(vector as! [Proto])
        }
        
        public init(_ vector: [T]) {
            self.vector = vector
            self.data = DataProcessorSetup.Vector(vector as! [Proto])
            self.session = SessionSetup.Vector(vector as! [Proto])
        }
        
        open func create() -> [T] {
            return []
        }
        
        public func register(_ element: T) {
            vector.append(element)
            data.register(element as! Proto)
            session.register(element as! Proto)
        }
        
        public func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
            return self.data.data(data, kind: kind)
        }
        
        public func session(_ session: Session.Proto, kind: Session.Kind) {
            self.session.session(session, kind: kind)
        }
        
        public func complete() -> Session.Proto? {
            return self.session.complete()
        }
    }
    
    open class Vector : VectorBase<Proto> {
    }
}


extension CaptureSetup {
    fileprivate class DataAdapter : Base {
        private let inner: DataProcessor.Setup
        
        init(data: DataProcessor.Setup) {
            self.inner = data
        }

        override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
            inner.data(data, kind: kind)
        }
    }

    fileprivate class SessionAdapter : Base {
        private let inner: Session.Setup
        
        init(session: Session.Setup) {
            self.inner = session
        }
        
        override func session(_ session: SessionProtocol, kind: Session.Kind) {
            self.inner.session(session, kind: kind)
        }
        
        override func complete() -> SessionProtocol? {
            return self.inner.complete()
        }
    }
}


public func cast(capture data: DataProcessor.Setup) -> Capture.Setup {
    return CaptureSetup.DataAdapter(data: data)
}

public func cast(capture session: Session.Setup) -> Capture.Setup {
    return CaptureSetup.SessionAdapter(session: session)
}
