//
//  Features.Screen.Preview.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 26.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AppKit

fileprivate extension NSStoryboard.SceneIdentifier {
    static var identifier: NSStoryboard.SceneIdentifier = "DisplayPreviewViewController"
}

class DisplayPreviewView : NSView {
    
    @IBOutlet public var imageView: NSImageView!
    @IBOutlet public var button: NSButton!
    var representedObject: Any?
    
    static func instantiate(storyboard: NSStoryboard?) -> DisplayPreviewView? {
        let controller = storyboard?.instantiateController(withIdentifier: .identifier) as? NSViewController
        return controller?.view as? DisplayPreviewView
        
    }
}
