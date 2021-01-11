//
//  WindowController.swift
//  Capture
//
//  Created by Ivan Kh on 13.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AppKit

class MainWindowController : NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.level = .floating + 1
    }
}
