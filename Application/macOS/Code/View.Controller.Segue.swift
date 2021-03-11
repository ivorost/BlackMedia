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
        
        let sampleBufferViews = preview.sampleBufferViews
        
        if let urls = previewWindow.object?.urls, urls.count > 0 {
            var info = [Viewer.Info]()
            
            for i in 0 ..< min(urls.count, sampleBufferViews.count) {
                guard let sampleBufferView = sampleBufferViews[i] else { assert(false); return }
                sampleBufferView.layer = sampleBufferView.makeBackingLayer()
                info.append((urls[i], sampleBufferView))
            }
            
            let viewer = Viewer(info)
            
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
                        preview.window = previewWindow
                        previewWindow.session = session
                        previewWindow.videoSize = viewer.videoSize
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


fileprivate extension Viewer {
    var videoSize: CGSize {
        let size0 = readers.count > 0 ? readers[0].processor?.videoSize ?? CGSize.zero : CGSize.zero
        let size1 = readers.count > 1 ? readers[1].processor?.videoSize ?? CGSize.zero : CGSize.zero
        let size2 = readers.count > 2 ? readers[2].processor?.videoSize ?? CGSize.zero : CGSize.zero
        let size3 = readers.count > 3 ? readers[3].processor?.videoSize ?? CGSize.zero : CGSize.zero

        return CGSize(width: max(size0.width + size1.width, size2.width + size3.width),
                      height: max(size0.height + size1.height, size2.height + size3.height))
    }
}
