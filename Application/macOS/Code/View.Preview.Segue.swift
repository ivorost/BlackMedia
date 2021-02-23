//
//  View.Preview.Segue.swift
//  Application-macOS
//
//  Created by Ivan Kh on 19.02.2021.
//

import Cocoa

class ToolbarSegue : NSStoryboardSegue {
    override func perform() {
        guard
            let preview = sourceController as? PreviewController,
            let toolbar = destinationController as? ToolbarController
        else { assert(false); return }
        
        toolbar.preview = preview
        
        super.perform()
    }
}
