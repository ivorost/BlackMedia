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
        private let selector: Selector

        private var peer: Network.Peer.Proto? {
            return selector.peer
        }

        convenience init() {
            self.init(.init())
        }
        
        init(_ selector: Selector) {
            self.selector = selector
        }
    }
}


extension Peer.Put : Data.Processor.Proto {
    func process(data: Data) {
        peer?.put(data)
    }
}


extension Peer {
    class Get {
        private let next: Data.Processor.Proto
        private let selector: Selector
        private var peerDisposable: AnyCancellable?
        private var selectorDisposable: AnyCancellable?

        init(selector: Selector, next: Data.Processor.Proto) {
            self.selector = selector
            self.next = next
        }
        
        private func peer(changed peer: Network.Peer.Proto?) {
            peerDisposable?.cancel()
            peerDisposable = peer?.get.sink(receiveCompletion: {_ in }, receiveValue: peer(get:))
        }
        
        private func peer(get data: Data) {
            next.process(data: data)
        }
    }
}


extension Peer.Get : Session.Proto {
    func start() throws {
        selectorDisposable = selector.$peer.sink(receiveValue: peer(changed:))
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
    func process(data: Data) {
        next.process(data: data)
    }
}


extension Peer.Get {
    class Setup : Network.Setup.Get {
        private let selector: Peer.Selector
        
        public init(selector: Peer.Selector,
                    root: Capture.Setup.Proto,
                    session: Session.Kind,
                    target: Data.Processor.Kind,
                    network: Data.Processor.Kind,
                    output: Data.Processor.Kind) {
            self.selector = selector
            super.init(root: root, session: session, target: target, network: network, output: output)
        }

        public override func network(for next: Data.Processor.Proto) -> Data.Processor.Proto & Session.Proto {
            return Peer.Get(selector: selector, next: next)
        }
    }
}
