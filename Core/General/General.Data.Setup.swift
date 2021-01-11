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
