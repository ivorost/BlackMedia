//
//  AppKit.ViewController.swift
//
//  Created by Ivan Kh on 04/10/2018.
//  Copyright © 2014-2019. All rights reserved.
//

#if os(OSX)
import AppKit

public typealias FuncWithAlert = (NSAlert) -> Void

public extension NSViewController {
    @discardableResult func sheetWarning(message: String?,
                                         informative: String?,
                                         customize: FuncWithAlert? = nil) -> NSApplication.ModalResponse {
        return NSAlert.sheetWarning(window: view.window,
                                    message: message,
                                    informative: informative,
                                    customize: customize)
    }
    
    @discardableResult func sheetWarning(message: String?,
                                         attributedInformative: NSAttributedString?,
                                         customize: FuncWithAlert? = nil) -> NSApplication.ModalResponse {
        return NSAlert.sheetWarning(window: view.window,
                                    message: message,
                                    attributedInformative: attributedInformative,
                                    customize: customize)
    }
}
#endif
