//
//  View.Controller.Segue.swift
//  Application-macOS
//
//  Created by Ivan Kh on 16.02.2021.
//

import Cocoa

class PreviewSegue : NSStoryboardSegue {
    override func perform() {
        guard
            let dialog = sourceController as? ViewController,
            let previewWindow = destinationController as? PreviewWindowController,
            let preview = previewWindow.contentViewController as? PreviewController
        else { return }
        
        if let url = previewWindow.object?.url {
            preview.sampleBufferView.layer = preview.sampleBufferView.makeBackingLayer()
            
            let viewer = Viewer(url: url, view: preview.sampleBufferView)
            
            guard var session = viewer.setup() else {
                dialog.show(error: nil)
                return
            }
            
            session = PreviewSegueSession(next: session, view: dialog, preview: previewWindow)
        
            DispatchQueue.global().async {
                do {
                    try session.start()

                    dispatchMainSync {
                        super.perform()
                        dialog.add(session)
                        previewWindow.session = session
                        
                        let videoSize = viewer.reader?.processor?.videoSize
                        
                        previewWindow.videoSize = videoSize
                        assert(videoSize != nil)
                    }
                }
                catch {
                    dialog.show(error: error)
                }
            }
        }
        else {
            dialog.show(error: nil)
        }
    }
}


fileprivate class PreviewSegueSession : Session.Proto {
    private var next: Session.Proto?
    private let view: ViewController
    private let preview: PreviewWindowController
    private var stopped = false
    
    init(next: Session.Proto, view: ViewController, preview: PreviewWindowController) {
        self.next = next
        self.view = view
        self.preview = preview
    }
    
    func start() throws {
        try next?.start()
    }
    
    func stop() {
        guard !stopped else { return }
        
        stopped = true
        preview.window?.close()
        next?.stop()
        next = nil
        preview.session = nil
        view.remove(self)
    }
}
