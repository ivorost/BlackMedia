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
    enum PacketType : UInt8 {
        // utilities
        // 0 ... 63
        case undefined = 0
        case ack       = 1
        case screen    = 2

        // video
        // 64 ... 127
        case videoH264 = 64

        // audio
        // 128 ... 192
        case audioAAC  = 128

        // events
        // 192 ... 255
        case nsevent   = 192
        case cgevent   = 193
    }
}


public extension Network.Setup {
    class Put : Data.Setup.Default {
        init(root: Data.Setup.Proto, data: Data.Processor.AnyProto, target: Data.Processor.Kind) {
            super.init(root: root,
                       targetKind: target,
                       selfKind: .networkDataOutput,
                       create: { Data.Processor.Base(prev: $0, next: data) })
        }
    }
}

public typealias DataAndSession = ProcessorProtocol<Data> & Session.Proto

extension Network.Setup {
    open class Get : Capture.Setup.Slave {
        private var network: Data.Processor.AnyProto?
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
        
        open func network(for next: Data.Processor.AnyProto, session: inout Session.Proto) -> Data.Processor.AnyProto {
            return Data.Processor.shared
        }
        
        public override func session(_ session: Session.Proto, kind: Session.Kind) {
            if kind == .initial {
                let nextData: Data.Processor.AnyProto = root.data(Data.Processor.shared, kind: self.output)
                var networkSession: Session.Proto = Session.shared
                let network = network(for: nextData, session: &networkSession)

                root.session(networkSession, kind: self.session)
                self.network = root.data(network, kind: self.networkKind)
            }
        }
    }
}
