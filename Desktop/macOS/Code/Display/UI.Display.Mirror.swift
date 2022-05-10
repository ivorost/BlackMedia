//
//  UI.Display.Mirror.swift
//  Capture
//
//  Created by Ivan Kh on 12.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AppKit


class DisplayMirrorWindowController : NSWindowController, NSWindowDelegate {
    var session: Session.Proto?
    
    var viewController: DisplayMirrorController? {
        return contentViewController as? DisplayMirrorController
    }
    
    func windowWillClose(_ notification: Notification) {
        let session = self.session
        
        DispatchQueue.global().async {
            session?.stop()
        }
    }
}


class DisplayMirrorController : NSViewController  {
    @IBOutlet public var sampleBufferView: SampleBufferDisplayView!
}
