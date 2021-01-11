//
//  General.Data.Setup.swift
//  Capture
//
//  Created by Ivan Kh on 25.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation


protocol DataProcessorSetupProtocol : class {
    func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol
}


class DataProcessorSetup : DataProcessorSetupProtocol {
    static let shared = DataProcessorSetup()
    
    func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        return data
    }
}


extension DataProcessor {
    typealias Setup = DataProcessorSetupProtocol
}


extension DataProcessorSetup {
    typealias Proto = DataProcessorSetupProtocol
    typealias Processor = DataProcessorProtocol
}


extension DataProcessorSetup {
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


extension DataProcessorSetup {
    class Default : Slave {
        private let targetKind: DataProcessor.Kind
        private let selfKind: DataProcessor.Kind
        private let create: (DataProcessor.Proto) -> DataProcessor.Proto
        
        init(root: DataProcessor.Setup,
             targetKind: DataProcessor.Kind,
             selfKind: DataProcessor.Kind,
             create: @escaping (DataProcessor.Proto) -> DataProcessor.Proto) {
            
            self.targetKind = targetKind
            self.selfKind = selfKind
            self.create = create
            super.init(root: root)
        }
        
        init(prev: DataProcessor.Proto,
             kind: DataProcessor.Kind) {
            self.targetKind = kind
            self.selfKind = .other
            self.create = { DataProcessor(prev: prev, next: $0) }
            super.init(root: DataProcessorSetup.shared)
        }
        
        override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
            var result = data
            
            if kind == targetKind {
                result = root.data(create(result), kind: selfKind)
            }
            
            return super.data(result, kind: kind)
        }
    }
}
