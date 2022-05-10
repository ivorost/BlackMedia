//
//  Network.General.swift
//  Capture
//
//  Created by Ivan Kh on 22.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation


public final class Network {
    public final class Setup {}
}


public extension Network {
    enum PacketType : UInt32 {
        case undefined = 0
        case video
        case nsevent
        case cgevent
        case display
    }
}


public extension Network.Setup {
    class Put : Data.Setup.Default {
        init(root: Data.Setup.Proto, data: Data.Processor.Proto, target: Data.Processor.Kind) {
            super.init(root: root,
                       targetKind: target,
                       selfKind: .networkDataOutput,
                       create: { Data.Processor.Base(prev: $0, next: data) })
        }
    }
}


extension Network.Setup {
    open class Get : Capture.Setup.Slave {
        private var network: Data.Processor.Proto?
        private let session: Session.Kind
        private let target: Data.Processor.Kind
        private let networkKind: Data.Processor.Kind
        private let output: Data.Processor.Kind

        public init(root: Capture.Setup.Proto,
                    session: Session.Kind,
                    target: Data.Processor.Kind,
                    network: Data.Processor.Kind,
                    output: Data.Processor.Kind) {
            self.session = session
            self.networkKind = network
            self.output = output
            self.target = target
            super.init(root: root)
        }
        
        open func network(for next: Data.Processor.Proto) -> Data.Processor.Proto & Session.Proto {
            return Capture.shared
        }
        
        public override func session(_ session: Session.Proto, kind: Session.Kind) {
            if kind == .initial {
                let nextData: Data.Processor.Proto = root.data(Data.Processor.shared, kind: self.output)
                let network = network(for: nextData)
                
                root.session(network, kind: self.session)
                self.network = root.data(network, kind: self.networkKind)
            }
        }
        
//        public override func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
//            var result = data
//            
//            if kind == target {
//                if let network = network {
//                    result = Data.Processor.Base(prev: result, next: network)
//                }
//                else {
//                    assert(false)
//                }
//            }
//            
//            return super.data(result, kind: kind)
//        }
    }
}
