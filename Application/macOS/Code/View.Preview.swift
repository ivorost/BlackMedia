//
//  Preview.swift
//  Application-macOS
//
//  Created by Ivan Kh on 15.02.2021.
//

import Cocoa
import AVFoundation


class PreviewController: NSViewController {
    @IBOutlet private(set) var sampleBufferView: SampleBufferDisplayView!
    weak var window: PreviewWindowController?
}


class PreviewWindowController: NSWindowController, NSWindowDelegate {
    var session: Session.Proto?
    
    var videoSize: CGSize? {
        didSet {
            if Settings.shared.sizeToOriginal {
                sizeToOriginal()
            }
            else {
                sizeToFit()
            }
        }
    }
    
    func sizeToFit() {
        guard let videoSize = videoSize,
              let screen = NSScreen.main,
              let titlebarHeight = window?.titlebarHeight
        else { assert(false); return }
    
        // for screen sharing we have to compare scales or event physical size
        
        var rect = CGRect(x: 0,
                          y: 0,
                          width: videoSize.width,
                          height: videoSize.height)
        var screenRect = screen.frame
        
        screenRect.size.height -= titlebarHeight
        
        if rect.width > screen.frame.width {
            rect.size.height *= screen.frame.width / rect.width
            rect.size.width = screen.frame.width
        }
        
        if rect.height > screen.frame.height {
            rect.size.width *= screen.frame.height / rect.height
            rect.size.height = screen.frame.height
        }
        
        rect.size.height += titlebarHeight
        rect.origin.x = (screen.frame.size.width - rect.width) / 2
        rect.origin.y = screen.frame.size.height - rect.height - (NSApp.menu?.menuBarHeight ?? 0)
        
        window?.setFrame(rect, display: true, animate: true)
        Settings.shared.sizeToOriginal = false
    }
    
    func sizeToOriginal() {
        guard let videoSize = videoSize,
              let screen = NSScreen.main,
              let titlebarHeight = window?.titlebarHeight
        else { assert(false); return }

        var rect = CGRect(x: (screen.frame.width - videoSize.width) / 2.0,
                          y: 0,
                          width: videoSize.width,
                          height: videoSize.height + titlebarHeight)

        rect.origin.y = screen.frame.height - rect.height - (NSApp.menu?.menuBarHeight ?? 0)
        
        window?.setFrame(rect, display: true, animate: true)
        Settings.shared.sizeToOriginal = true
    }
    
    func windowWillClose(_ notification: Notification) {
        session?.stop()
    }
}
