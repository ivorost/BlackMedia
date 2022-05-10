//
//  General.Data.Setup.swift
//  Capture
//
//  Created by Ivan Kh on 25.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation


public protocol DataProcessorSetupProtocol : AnyObject {
    func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto
}


public extension Data {
    final class Setup {
        public static let shared: Proto = Base()
    }
}


public extension Data.Setup {
    typealias Proto = DataProcessorSetupProtocol
    typealias Processor = Data.Processor.Proto
}


public extension Data.Setup {
    class Base : Proto {
        public func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
            return data
        }
    }
}


public extension Data.Setup {
    class Slave : Base {
        private(set) weak var _root: Proto?
        
        init(root: Proto) {
            self._root = root
        }
        
        var root: Proto {
            return _root ?? shared
        }
    }
}


public extension Data.Setup {
    class Vector : ProcessorWithVector<Proto>, Proto {
        public func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
            return vector.reduce(data) { $1.data($0, kind: kind) }
        }
    }
}


public extension Data.Setup {
    class Default : Slave {
        private let targetKind: Data.Processor.Kind
        private let selfKind: Data.Processor.Kind
        private let create: (Data.Processor.Proto) -> Data.Processor.Proto
        
        public init(root: Data.Setup.Proto,
                    targetKind: Data.Processor.Kind,
                    selfKind: Data.Processor.Kind,
                    create: @escaping (Data.Processor.Proto) -> Data.Processor.Proto) {
            
            self.targetKind = targetKind
            self.selfKind = selfKind
            self.create = create
            super.init(root: root)
        }
        
        public init(prev: Data.Processor.Proto,
                    kind: Data.Processor.Kind) {
            self.targetKind = kind
            self.selfKind = .other
            self.create = { Data.Processor.Base(prev: prev, next: $0) }
            super.init(root: shared)
        }
        
        public override func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
            var result = data
            
            if kind == targetKind {
                result = root.data(create(result), kind: selfKind)
            }
            
            return super.data(result, kind: kind)
        }
    }
}


public extension Data.Setup {
    class Test : Capture.Setup.Slave {
        private let kbits: UInt
        private let interval: TimeInterval
        
        public init(root: Capture.Setup.Proto, kbits: UInt, interval: TimeInterval) {
            self.kbits = kbits
            self.interval = interval
            super.init(root: root)
        }
        
        public override func session(_ session: Session.Proto, kind: Session.Kind) {
            if kind == .initial {
                let next = root.data(Data.Processor.shared, kind: .capture)
                let test = Data.Processor.Test(next: next, kbits: kbits)
                let flush = Session.DispatchSync(session: Flushable.Periodically(interval: interval, next: test),
                                                 queue: DispatchQueue.main)
                
                root.session(flush, kind: .other)
            }
        }
    }
}
