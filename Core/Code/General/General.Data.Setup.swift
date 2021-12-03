//
//  General.Data.Setup.swift
//  Capture
//
//  Created by Ivan Kh on 25.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation


public protocol DataProcessorSetupProtocol : AnyObject {
    func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol
}


public class DataProcessorSetup : DataProcessorSetupProtocol {
    public static let shared = DataProcessorSetup()
    
    public func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        return data
    }
}


public extension DataProcessor {
    typealias Setup = DataProcessorSetupProtocol
}


extension DataProcessorSetup {
    typealias Proto = DataProcessorSetupProtocol
    typealias Processor = DataProcessorProtocol
}


public extension DataProcessorSetup {
    class Slave : DataProcessorSetup {
        private(set) weak var _root: Proto?
        
        init(root: Proto) {
            self._root = root
        }
        
        var root: Proto {
            return _root ?? DataProcessorSetup.shared
        }
    }
}

extension DataProcessorSetup {
    class Vector : ProcessorWithVector<Proto>, Proto {
        func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
            return vector.reduce(data) { $1.data($0, kind: kind) }
        }
    }
}


public extension DataProcessorSetup {
    class Default : Slave {
        private let targetKind: DataProcessor.Kind
        private let selfKind: DataProcessor.Kind
        private let create: (DataProcessor.Proto) -> DataProcessor.Proto
        
        public init(root: DataProcessor.Setup,
             targetKind: DataProcessor.Kind,
             selfKind: DataProcessor.Kind,
             create: @escaping (DataProcessor.Proto) -> DataProcessor.Proto) {
            
            self.targetKind = targetKind
            self.selfKind = selfKind
            self.create = create
            super.init(root: root)
        }
        
        public init(prev: DataProcessor.Proto,
             kind: DataProcessor.Kind) {
            self.targetKind = kind
            self.selfKind = .other
            self.create = { DataProcessor(prev: prev, next: $0) }
            super.init(root: DataProcessorSetup.shared)
        }
        
        public override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
            var result = data
            
            if kind == targetKind {
                result = root.data(create(result), kind: selfKind)
            }
            
            return super.data(result, kind: kind)
        }
    }
}


public extension DataProcessor.Test {
    class Setup : CaptureSetup.Slave {
        private let kbits: UInt
        private let interval: TimeInterval
        
        public init(root: Capture.Setup, kbits: UInt, interval: TimeInterval) {
            self.kbits = kbits
            self.interval = interval
            super.init(root: root)
        }
        
        public override func session(_ session: Session.Proto, kind: Session.Kind) {
            if kind == .initial {
                let next = root.data(DataProcessor.shared, kind: .capture)
                let test = DataProcessor.Test(next: next, kbits: kbits)
                let flush = Session.DispatchSync(session: Flushable.Periodically(interval: interval, next: test),
                                                 queue: DispatchQueue.main)
                
                root.session(flush, kind: .other)
            }
        }
    }
}
