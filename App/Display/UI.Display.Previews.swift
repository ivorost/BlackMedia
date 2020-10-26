//
//  Features.Screen.Previews.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 27.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AppKit


fileprivate extension UInt32 {
    static var maxDisplaysCount: UInt32 = 100
}


fileprivate extension Int {
    static var maxDisplaysCount: Int = Int(UInt32.maxDisplaysCount)
}


class DisplayPreviewsController : NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var displaysIDs = [CGDirectDisplayID](repeating: CGMainDisplayID(), count: .maxDisplaysCount)
        var displaysCount: UInt32 = 0
        var origin = CGPoint.zero
        
        CGGetActiveDisplayList(.maxDisplaysCount, &displaysIDs, &displaysCount)
        displaysIDs.removeLast(displaysIDs.count - Int(displaysCount))
        
        for displayID in displaysIDs {
            guard
                let image = CGDisplayCreateImage(displayID),
                let preview = DisplayPreviewView.instantiate(storyboard: self.storyboard)
                else { assert(false); continue }
            
            preview.frame = NSRect(origin: origin, size: preview.frame.size)
            preview.imageView.image = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
            preview.representedObject = displayID
            
            if let radioButton = preview.button as? RadioButton {
                radioButton.radioButtonContainer = self.view
            }
            
            if displayID == CGMainDisplayID() {
                preview.button.state = .on
            }
            
            self.view.addSubview(preview)
            
            if origin.x + preview.frame.width * 2 > self.view.frame.width {
                origin.x = 0
                origin.y += preview.frame.height
            }
            else {
                origin.x += preview.frame.width
            }
        }
    }
    
    var displays: [CGDirectDisplayID] {
        var result = [CGDirectDisplayID]()
        
        for view in self.view.subviews {
            guard
                let previewView = view as? DisplayPreviewView,
                let representedObject = previewView.representedObject as? CGDirectDisplayID
                else { assert(false); continue }
            guard
                previewView.button.state == .on
                else { continue }

            result.append(representedObject)
        }
                
        return result
    }
}
