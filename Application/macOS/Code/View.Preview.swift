//
//  Preview.swift
//  Application-macOS
//
//  Created by Ivan Kh on 15.02.2021.
//

import Cocoa
import AVFoundation


struct PreviewObject {
    let index: Int
    let urls: [URL]
}


class PreviewController: NSViewController {
    @IBOutlet private(set) var sampleBufferView1: SampleBufferDisplayView?
    @IBOutlet private(set) var sampleBufferView2: SampleBufferDisplayView?
    @IBOutlet private(set) var sampleBufferView3: SampleBufferDisplayView?
    @IBOutlet private(set) var sampleBufferView4: SampleBufferDisplayView?
    weak var window: PreviewWindowController?

    var sampleBufferViews: [SampleBufferDisplayView?] {
        return [ sampleBufferView1, sampleBufferView2, sampleBufferView3, sampleBufferView4 ]
    }
}


class PreviewWindowController: NSWindowController, NSWindowDelegate {
    var session: Session.Proto?
    var object: PreviewObject?
    
    private var prefferedScreen: NSScreen? {
        guard let object = object else { assert(false); return NSScreen.main }
        return object.index < NSScreen.screens.count ? NSScreen.screens[object.index] : NSScreen.main
    }
    
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
              let screen = prefferedScreen,
              let titlebarHeight = window?.titlebarHeight
        else { assert(false); return }
    
        // for screen sharing we have to compare scales or event physical size
    
        let padding = object?.urls.count ?? 0 > 1
            ? CGSize(width: 24, height: 24)
            : CGSize.zero
        var screenFrame = screen.frame

        screenFrame.size.width -= padding.width
        screenFrame.size.height -= padding.height

        var rect = CGRect(x: screenFrame.origin.x,
                          y: screenFrame.origin.y,
                          width: videoSize.width,
                          height: videoSize.height)
        
        if rect.width > screen.frame.width {
            rect.size.height *= screenFrame.width / rect.width
            rect.size.width = screenFrame.width
        }
        
        if rect.height > screenFrame.height {
            rect.size.width *= screenFrame.height / rect.height
            rect.size.height = screenFrame.height - titlebarHeight
        }
        
        rect.size.width += padding.width
        rect.size.height += titlebarHeight + padding.height
        
        rect.origin.x = screen.frame.origin.x
            + (screen.frame.size.width - rect.width) / 2
        rect.origin.y = screen.frame.origin.y
            + screen.frame.size.height
            - rect.height
            - (NSApp.menu?.menuBarHeight ?? 0)
        
        window?.setFrame(rect, display: true, animate: true)
        Settings.shared.sizeToOriginal = false
    }
    
    func sizeToOriginal() {
        guard let videoSize = videoSize,
              let screen = prefferedScreen,
              let titlebarHeight = window?.titlebarHeight
        else { assert(false); return }

        var rect = CGRect(x: screen.frame.origin.x + (screen.frame.width - videoSize.width) / 2.0,
                          y: screen.frame.origin.y,
                          width: videoSize.width,
                          height: videoSize.height + titlebarHeight)

        rect.origin.y = screen.frame.origin.y + screen.frame.height - rect.height - (NSApp.menu?.menuBarHeight ?? 0)
        
        window?.setFrame(rect, display: true, animate: true)
        Settings.shared.sizeToOriginal = true
    }
    
    func windowWillClose(_ notification: Notification) {
        session?.stop()
    }
}
