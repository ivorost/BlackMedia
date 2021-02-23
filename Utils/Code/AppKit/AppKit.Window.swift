//
//  AppKit.Window.swift
//  Utils
//
//  Created by Ivan Kh on 18.02.2021.
//

#if os(OSX)
import AppKit

public extension NSWindow {
    var titlebarHeight: CGFloat {
        frame.height - contentRect(forFrameRect: frame).height
    }
}


public class FreeSizeWindow : NSWindow {
    public override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }
}

#endif
