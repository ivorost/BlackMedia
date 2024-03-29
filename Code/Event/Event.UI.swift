//
//  Event.UI.swift
//  Capture
//
//  Created by Ivan Kh on 04.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

#if canImport(AppKit)
import AppKit
#endif


#if canImport(AppKit)
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
#endif


#if canImport(AppKit)
public extension EventCapture.Window {
    class Setup : Session.Setup.Slave {
        private let window: NSWindow
        
        public init(root: Session.Setup.Proto, window: NSWindow) {
            self.window = window
            super.init(root: root)
        }

        public override func session(_ session: Session.Proto, kind: Session.Kind) {
            if kind == .initial {
                let session = Session.DispatchSync(session: EventCapture.Window(window: window),
                                                   queue: DispatchQueue.main)
                root.session(session, kind: .other)
            }
        }
    }
}
#endif
