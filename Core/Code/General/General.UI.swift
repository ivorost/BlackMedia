//
//  General.UI.swift
//  Capture
//
//  Created by Ivan Kh on 27.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

#if os(OSX)
import AppKit

public class CheckboxChain<T> {
    private let checkbox: NSButton
    private let nextVar: T
    private let off: T
    
    public init(next: T, checkbox: NSButton, off: T) {
        self.checkbox = checkbox
        self.nextVar = next
        self.off = off
    }
    
    var next: T {
        return checkbox.state == .on
            ? nextVar
            : off
    }
}
#endif
