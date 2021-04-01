//
//  View.Toolbar.Segue.swift
//  Application-macOS
//
//  Created by Ivan Kh on 11.03.2021.
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
