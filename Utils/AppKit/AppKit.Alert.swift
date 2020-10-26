//
//  Dialog.swift
//
//  Created by Ivan Kh on 26/09/17.
//  Copyright © 2014-2019. All rights reserved.
//

import Cocoa

extension String {
    static var OK = "OK"
    static var Cancel = "Cancel"
    static let Yes = "Yes"
    static let No = "No"
}

extension NSAlert {
    
    public static let defaultWidth: CGFloat = 270
    public static let wideWidth: CGFloat = 375

    public func setInformativeAttributedText(_ text: NSAttributedString, width: CGFloat = NSAlert.defaultWidth) {
        let label = NSTextView(frame: NSMakeRect(0, 0, width, 0))
        
        label.isEditable = false
        label.textStorage?.append(text)
        label.backgroundColor = NSColor.clear
        label.sizeToFit()

        accessoryView = label
    }
}

private struct AlertInfo : Equatable {
    var title: String?
    var message: String?
    var informative: String?
    var attributedInformative: NSAttributedString?
    
    static func == (lhs: AlertInfo, rhs: AlertInfo) -> Bool {
        return lhs.title == rhs.title &&
        lhs.message == rhs.message &&
        lhs.informative == rhs.informative &&
        lhs.attributedInformative == rhs.attributedInformative
    }
}

private var activeAlertInfo: AlertInfo?

extension NSAlert {
    
    static private func prepareAlert(style: NSAlert.Style,
                              title: String?,
                              message: String?,
                              informative: String?,
                              attributedInformative attributedInformative_: NSAttributedString?,
                              customize: FuncWithAlert?) -> NSAlert {
        let symbolsNumberForWideWidth = 96
        let alert = NSAlert()
        let messageCount = message?.count ?? 0
        let informativeCount = informative?.count ?? 0
        var attributedInformativeLocal = attributedInformative_
        let attributedInformativeCount = attributedInformativeLocal?.length ?? 0
        
        alert.window.title = title ?? ""
        alert.alertStyle = style
        alert.messageText = message ?? ""
        
        if let informative = informative, attributedInformativeLocal == nil {
            attributedInformativeLocal = NSAttributedString(string: informative)
        }
        
        if let attributedInformativeLocal = attributedInformativeLocal,
            let mutableAttributedInformative = attributedInformativeLocal.mutableCopy() as? NSMutableAttributedString {
            
            mutableAttributedInformative.addAttribute(.foregroundColor,
                                                      value: NSColor.secondaryLabelColor,
                                                      range: NSRange(location: 0,
                                                                     length: attributedInformativeLocal.length))
            
            alert.setInformativeAttributedText(mutableAttributedInformative, width: NSAlert.defaultWidth)
        }
        else {
            alert.informativeText = informative ?? ""
        }
        
        customize?(alert)
        
        var wide = false
        
        if messageCount + informativeCount + attributedInformativeCount > symbolsNumberForWideWidth {
            wide = true
        }
        if alert.buttons.count > 2 {
            wide = true
        }
        
        // actual width 375 + 125
        if wide {
            let frame = NSRect(x: 0, y: 0, width: NSAlert.wideWidth, height: alert.accessoryView?.frame.height ?? 0)
            
            if alert.accessoryView != nil {
                alert.accessoryView?.frame = frame
            }
            else {
                alert.accessoryView = NSView(frame: frame)
            }
        }
        
        return alert
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: - Warning alert
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    @discardableResult static private func alertWarning(title: String?,
                                                 message: String?,
                                                 informative: String?,
                                                 attributedInformative: NSAttributedString?,
                                                 customize: FuncWithAlert? = nil) -> NSApplication.ModalResponse {
        var result = NSApplication.ModalResponse(rawValue: 0)
        let alertInfo = AlertInfo(title: title, message: message, informative: informative, attributedInformative: attributedInformative)
        guard alertInfo != activeAlertInfo else { return result }
        
        dispatchMainSync {
            let alert = prepareAlert(style: .warning,
                                     title: title,
                                     message: message,
                                     informative: informative,
                                     attributedInformative: attributedInformative,
                                     customize: customize)
            
            activeAlertInfo = alertInfo
            result = alert.runModal()
            activeAlertInfo = nil
        }
        
        return result
    }
    
    @discardableResult static public func alertWarning(title: String?,
                                                message: String?,
                                                attributedInformative: NSAttributedString?,
                                                customize: FuncWithAlert? = nil) -> NSApplication.ModalResponse {
        return alertWarning(title: title,
                            message: message,
                            informative: nil,
                            attributedInformative: attributedInformative,
                            customize: customize)
    }
    
    @discardableResult static public func alertWarning(title: String?,
                                                message: String?,
                                                informative: String?,
                                                customize: FuncWithAlert? = nil) -> NSApplication.ModalResponse {
        return alertWarning(title: title,
                            message: message,
                            informative: informative,
                            attributedInformative: nil,
                            customize: customize)
    }
    
    @discardableResult static public func alertWarning(message: String?,
                                                informative: String?,
                                                attributedInformative: NSAttributedString?,
                                                customize: FuncWithAlert? = nil) -> NSApplication.ModalResponse {
        return alertWarning(title: nil,
                            message: message,
                            informative: informative,
                            attributedInformative: attributedInformative,
                            customize: customize)
    }
    
    @discardableResult static public func alertWarning(message: String?,
                                                attributedInformative: NSAttributedString?,
                                                customize: FuncWithAlert? = nil) -> NSApplication.ModalResponse {
        return alertWarning(title: nil,
                            message: message,
                            informative: nil,
                            attributedInformative: attributedInformative,
                            customize: customize)
    }
    
    @discardableResult static public func alertWarning(message: String?,
                                                informative: String?,
                                                customize: FuncWithAlert? = nil) -> NSApplication.ModalResponse {
        return alertWarning(title: nil,
                            message: message,
                            informative: informative,
                            customize: customize)
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: - Warning sheet
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    @discardableResult static public func sheetWarning(window: NSWindow?,
                                                message: String?,
                                                informative: String?,
                                                attributedInformative: NSAttributedString?,
                                                customize: FuncWithAlert? = nil) -> NSApplication.ModalResponse {
        var result = NSApplication.ModalResponse.alertFirstButtonReturn
        var window1 = window
        
        window1 = window1 ?? NSApp.keyWindow
        window1 = window1 ?? NSApp.mainWindow
        
        guard let window2 = window1 else {
            return alertWarning(message: message, informative: informative, attributedInformative: attributedInformative)
        }
        
        dispatchMainSync {
            waitWhileSheetActive(inWindow: window2)
            
            let alert = prepareAlert(style: .warning,
                                     title: nil,
                                     message: message,
                                     informative: informative,
                                     attributedInformative: attributedInformative) {
                                        $0.addButton(withTitle: .OK)
                                        customize?($0)
            }
            
            alert.beginSheetModal(for: window2) { answer in
                NSApp.stopModal()
                result =  answer
            }
            
            NSApp.runModal(for: alert.window)
        }
        
        return result
    }
    
    @discardableResult static public func sheetWarning(window: NSWindow?,
                                                message: String?,
                                                attributedInformative: NSAttributedString?,
                                                customize: FuncWithAlert? = nil) -> NSApplication.ModalResponse {
        return sheetWarning(window: window,
                            message: message,
                            informative: nil,
                            attributedInformative: attributedInformative)
    }
    
    @discardableResult static public func sheetWarning(window: NSWindow?,
                                                message: String?,
                                                informative: String?,
                                                customize: FuncWithAlert? = nil) -> NSApplication.ModalResponse {
        return sheetWarning(window: window,
                            message: message,
                            informative: informative,
                            attributedInformative: nil,
                            customize: customize)
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: - Warning comfirm/decline
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    static public func confirmWarning(window: NSWindow,
                               title: String?,
                               message: String?,
                               informative: String?,
                               attributedInformative: NSAttributedString?,
                               ok: @escaping Func,
                               cancel: @escaping Func,
                               cancelIsDefault: Bool) {
        dispatchMainSync {
            let alert = prepareAlert(style: .warning,
                                     title: title,
                                     message: message,
                                     informative: informative,
                                     attributedInformative: attributedInformative) {
                                        if cancelIsDefault {
                                            $0.addButton(withTitle: .Cancel).keyEquivalent = String.escape
                                            $0.addButton(withTitle: .OK)
                                        }
                                        else {
                                            $0.addButton(withTitle: .OK)
                                            $0.addButton(withTitle: .Cancel).keyEquivalent = String.escape
                                        }
            }
            
            alert.beginSheetModal(for: window, completionHandler: { answer in
                if answer == .alertFirstButtonReturn {
                    cancelIsDefault ? cancel() : ok()
                }
                else {
                    cancelIsDefault ? ok() : cancel()
                }
                
                NSApp.stopModal()
            })
            
            NSApp.runModal(for: alert.window)
        }
    }
    
    static public func confirmWarning(window: NSWindow,
                               message: String?,
                               informative: String?,
                               ok: @escaping Func,
                               cancel: @escaping Func) {
        confirmWarning(window: window, title: nil, message: message,
                       informative: informative, attributedInformative: nil,
                       ok: ok, cancel: cancel, cancelIsDefault: true)
    }
    
    static public func confirmWarning(window: NSWindow,
                               message: String?,
                               attributedInformative: NSAttributedString?,
                               ok: @escaping Func) {
        confirmWarning(window: window, title: nil, message: message,
                       informative: nil, attributedInformative: attributedInformative,
                       ok: ok, cancel: {}, cancelIsDefault: true)
    }
    
    static public func confirmWarning(window: NSWindow,
                               message: String?,
                               informative: String?,
                               ok: @escaping Func) {
        confirmWarning(window: window, message: message,
                       informative: informative,
                       ok: ok, cancel: {})
    }
    
    static public func declineWarning(window: NSWindow,
                               message: String?,
                               attributedInformative: NSAttributedString?,
                               cancel: @escaping Func) {
        confirmWarning(window: window, title: nil, message: message,
                       informative: nil, attributedInformative: attributedInformative,
                       ok: {}, cancel: cancel, cancelIsDefault: true)
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: - Confirm sheet
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    static func confirmSheet(window: NSWindow?,
                      message: String?,
                      informative: String?,
                      attributedInformative: NSAttributedString?,
                      yes: @escaping Func) {
        dispatchMainSync {
            let alert = prepareAlert(style: .informational,
                                     title: nil,
                                     message: message,
                                     informative: informative,
                                     attributedInformative: attributedInformative) {
                                        $0.addButton(withTitle: .Yes)
                                        $0.addButton(withTitle: .No).keyEquivalent = String.escape
            }
            
            let callback = { (answer: NSApplication.ModalResponse) in
                if answer == .alertFirstButtonReturn {
                    yes()
                }
            }
            
            if let window = window {
                alert.beginSheetModal(for: window, completionHandler: { answer in
                    callback(answer)
                    NSApp.stopModal()
                })
                
                NSApp.runModal(for: alert.window)
            }
            else {
                callback(alert.runModal())
            }
        }
    }
    
    static public func confirmSheet(window: NSWindow?,
                             message: String?,
                             informative: String?,
                             yes: @escaping Func) {
        confirmSheet(window: window,
                     message: message,
                     informative: informative,
                     attributedInformative: nil,
                     yes: yes)
    }
    
    static public func confirmSheet(window: NSWindow?,
                             message: String?,
                             attributedInformative: NSAttributedString?,
                             yes: @escaping Func) {
        confirmSheet(window: window,
                     message: message,
                     informative: nil,
                     attributedInformative: attributedInformative,
                     yes: yes)
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: - Info sheet
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    static func infoSheet(window: NSWindow,
                   message: String?,
                   informative: String?,
                   attributedInformative: NSAttributedString?) {
        dispatchMainSync {
            let alert = prepareAlert(style: .informational,
                                     title: nil,
                                     message: message,
                                     informative: informative,
                                     attributedInformative: attributedInformative) {
                                        $0.addButton(withTitle: .OK)
            }
            
            alert.beginSheetModal(for: window, completionHandler: { answer in
                NSApp.stopModal()
            })
            
            NSApp.runModal(for: alert.window)
        }
    }
    
    static public func infoSheet(window: NSWindow,
                          message: String?,
                          informative: String?) {
        infoSheet(window: window,
                  message: message,
                  informative: informative,
                  attributedInformative: nil)
    }
    
    static public func infoSheet(window: NSWindow,
                          message: String?,
                          attributedInformative: NSAttributedString?) {
        infoSheet(window: window,
                  message: message,
                  informative: nil,
                  attributedInformative: attributedInformative)
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: - Utils
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    static public func waitWhileSheetActive(inWindow window: NSWindow?) {
        if let window = window, window.attachedSheet != nil {
            NSApp.runModal(for: window)
            NSApp.stopModal()
        }
    }
}
