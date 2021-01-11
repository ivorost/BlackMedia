//
//  Event.UI.swift
//  Capture
//
//  Created by Ivan Kh on 04.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AppKit


extension EventCapture {
    class Window : Session.Proto {
        private let window: NSWindow
        
        init(window: NSWindow) {
            self.window = window
        }
        
        func start() throws {
            self.window.makeFirstResponder(self.window.contentView)
            self.window.makeKey()
        }
        
        func stop() {
        }
    }
}


extension EventCapture.Window {
    class Setup : SessionSetup.Slave {
        private let window: NSWindow
        
        init(root: SessionSetup.Proto, window: NSWindow) {
            self.window = window
            super.init(root: root)
        }

        override func session(_ session: SessionProtocol, kind: Session.Kind) {
            if kind == .initial {
                let session = Session.DispatchSync(session: EventCapture.Window(window: window),
                                                   queue: DispatchQueue.main)
                root.session(session, kind: .other)
            }
        }
    }
}
