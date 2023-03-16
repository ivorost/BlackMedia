//
//  Peer.IO.swift
//  Camera
//
//  Created by Ivan Kh on 29.04.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import Foundation
import Combine


extension Peer {
    class Put {
        private let selector: any Selector.Proto

        private var peer: Network.Peer.Proto? {
            return selector.peer?.remote
        }

        convenience init() {
            self.init(Selector.General())
        }
        
        init(_ selector: any Selector.Proto) {
            self.selector = selector
        }
    }
}


extension Peer.Put : Data.Processor.Proto {
    func process(_ data: Data) {
        peer?.put(.data(data))
    }
}


extension Peer {
    class Get {
        private let next: Data.Processor.AnyProto
        private let selector: any Selector.Proto
        private var peerDisposable: AnyCancellable?
        private var selectorDisposable: AnyCancellable?

        init(selector: any Selector.Proto, next: Data.Processor.AnyProto) {
            self.selector = selector
            self.next = next
        }
        
        private func peer(changed peer: Network.Peer.Pair.Proto?) {
            peerDisposable?.cancel()
            peerDisposable = peer?.remote.get.sink(receiveCompletion: {_ in }, receiveValue: peer(get:))
        }
        
        private func peer(get data: Network.Peer.Data) {
            if case let .data(data) = data {
                next.process(data)
            }
        }
    }
}


extension Peer.Get : Session.Proto {
    func start() throws {
        selectorDisposable = selector.peerPublisher.sink(receiveValue: peer(changed:))
        peer(changed: selector.peer)
    }
    
    func stop() {
        peerDisposable?.cancel()
        selectorDisposable?.cancel()
        
        peerDisposable = nil
        selectorDisposable = nil
    }
}


extension Peer.Get : Data.Processor.Proto {
    func process(_ value: Data) {
        next.process(value)
    }
}

extension Peer.Get: CaptureProtocol {}

extension Peer.Get {
    class Setup : Network.Setup.Get {
        private let selector: any Peer.Selector.Proto
        
        public init(selector: any Peer.Selector.Proto,
                    root: Capture.Setup.Proto,
                    session: Session.Kind,
                    target: Data.Processor.Kind,
                    network: Data.Processor.Kind,
                    output: Data.Processor.Kind) {
            self.selector = selector
            super.init(root: root, session: session, target: target, network: network, output: output)
        }

        public override func network(for next: Data.Processor.AnyProto, session: inout Session.Proto) -> Data.Processor.AnyProto {
            let result = Peer.Get(selector: selector, next: next)
            session = result
            return result
        }
    }
}
