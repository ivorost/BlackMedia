//
//  Event.UI.swift
//  Capture
//
//  Created by Ivan Kh on 04.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AppKit


public extension EventCapture {
    class Window : Session.Proto {
        private let window: NSWindow
        
        public init(window: NSWindow) {
            self.window = window
        }
        
        public func start() throws {
            self.window.makeFirstResponder(self.window.contentView)
            self.window.makeKey()
        }
        
        public func stop() {
        }
    }
}


public extension EventCapture.Window {
    class Setup : SessionSetup.Slave {
        private let window: NSWindow
        
        public init(root: SessionSetup.Proto, window: NSWindow) {
            self.window = window
            super.init(root: root)
        }

        public override func session(_ session: SessionProtocol, kind: Session.Kind) {
            if kind == .initial {
                let session = Session.DispatchSync(session: EventCapture.Window(window: window),
                                                   queue: DispatchQueue.main)
                root.session(session, kind: .other)
            }
        }
    }
}
