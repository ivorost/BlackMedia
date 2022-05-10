//
//  AV.Setup.swift
//  Capture
//
//  Created by Ivan Kh on 23.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation


public protocol CaptureSetupProtocol : Session.Setup.Proto & Data.Setup.Proto {
}


public extension Capture {
    final class Setup {}
}


extension Capture.Setup {
    public typealias Proto = CaptureSetupProtocol
}

extension Capture.Setup {
    public static let queue = DispatchQueue.CreateCheckable("setup_queue")
}


extension Capture.Setup {
    open class Base : Proto {
        static let shared = Base()
        
        public func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
            return data
        }
        
        public func session(_ session: Session.Proto, kind: Session.Kind) {
        }
        
        public func complete() -> Session.Proto? {
            return Session.shared
        }
    }
}


extension Capture.Setup {
    open class Slave : Base {
        private(set) weak var _root: Proto?
        
        init(root: Proto) {
            self._root = root
        }
        
        var root: Proto {
            return _root ?? Capture.Setup.Base.shared
        }
    }
}


extension Capture.Setup {
    open class VectorBase<T> : ProcessorWithVectorProtocol & Proto {
        private(set) var vector: [T]
        private var data = Data.Setup.Vector([])
        private var session = Session.Setup.Vector([])

        public init() {
            vector = []
            vector = create()
            self.data = Data.Setup.Vector(vector as! [Proto])
            self.session = Session.Setup.Vector(vector as! [Proto])
        }
        
        public init(_ vector: [T]) {
            self.vector = vector
            self.data = Data.Setup.Vector(vector as! [Proto])
            self.session = Session.Setup.Vector(vector as! [Proto])
        }
        
        open func create() -> [T] {
            return []
        }
        
        public func append(_ element: T) {
            vector.append(element)
            data.append(element as! Proto)
            session.append(element as! Proto)
        }

        public func prepend(_ element: T) {
            vector.insert(element, at: 0)
            data.prepend(element as! Proto)
            session.prepend(element as! Proto)
        }

        public func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
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


extension Capture.Setup {
    fileprivate class DataAdapter : Base {
        private let inner: Data.Setup.Proto
        
        init(data: Data.Setup.Proto) {
            self.inner = data
        }

        override func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
            inner.data(data, kind: kind)
        }
    }

    fileprivate class SessionAdapter : Base {
        private let inner: Session.Setup.Proto
        
        init(session: Session.Setup.Proto) {
            self.inner = session
        }
        
        override func session(_ session: Session.Proto, kind: Session.Kind) {
            self.inner.session(session, kind: kind)
        }
        
        override func complete() -> Session.Proto? {
            return self.inner.complete()
        }
    }
}


public func cast(capture data: Data.Setup.Proto) -> Capture.Setup.Proto {
    return Capture.Setup.DataAdapter(data: data)
}

public func cast(capture session: Session.Setup.Proto) -> Capture.Setup.Proto {
    return Capture.Setup.SessionAdapter(session: session)
}
