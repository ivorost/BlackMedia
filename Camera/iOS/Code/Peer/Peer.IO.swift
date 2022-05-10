//
//  Peer.IO.swift
//  Camera
//
//  Created by Ivan Kh on 29.04.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import Foundation
import RxSwift

extension Peer {
    class Put {
        private let selector: Selector

        private var peer: Peer.Proto? {
            return selector.peer
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
        private var peerDisposable: Disposable?
        private var selectorDisposable: Disposable?

        init(selector: Selector, next: Data.Processor.Proto) {
            self.selector = selector
            self.next = next
            selectorDisposable = selector.rx.peer.subscribe(peer(changed:))
        }
        
        private func peer(changed event: RxSwift.Event<Peer.Proto?>) {
            peerDisposable?.dispose()
            peerDisposable = event.element??.rx.get.subscribe(peer(get:))
        }
        
        private func peer(get event: RxSwift.Event<Data>) {
            guard let data = event.element else { assertionFailure(); return }
            self.next.process(data: data)
        }
    }
}


extension Peer.Get : Session.Proto {
    func start() throws {
        
    }
    
    func stop() {
        peerDisposable?.dispose()
        selectorDisposable?.dispose()
    }
}


extension Peer.Get : Data.Processor.Proto {
    func process(data: Data) {
        assertionFailure()
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
