//
//  View.Toolbar.swift
//  Application-macOS
//
//  Created by Ivan Kh on 19.02.2021.
//

import Cocoa

class ToolbarController : NSViewController {
    
    weak var preview: PreviewController?
    
    @IBOutlet private var sizeToFitMenuItem: NSMenuItem!
    @IBOutlet private var sizeToOriginalMenuItem: NSMenuItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sizeToFitMenuItem.state = Settings.shared.sizeToOriginal ? .off : .on
        sizeToOriginalMenuItem.state = Settings.shared.sizeToOriginal ? .on : .off
    }
    
    // General actions -------------------------------------------------------------------------------------------------

    @IBAction private func closeAction(_ sender: Any) {
        view.window?.close()
    }

    @IBAction private func viewAction(_ sender: Any) {
        guard let view = sender as? NSButton,
              let menu = view.menu
        else { return }
        menu.popUp(positioning: nil, at: CGPoint(x: 0, y: view.frame.height + 5), in: view)
    }

    @IBAction private func fileTransferAction(_ sender: Any) {
        
    }

    @IBAction private func ctrlAltDelAction(_ sender: Any) {
        
    }

    @IBAction private func fullScreenAction(_ sender: Any) {
        view.window?.toggleFullScreen(sender)
    }

    @IBAction private func hideAction(_ sender: Any) {
        
    }

    // View actions ----------------------------------------------------------------------------------------------------
    
    @IBAction private func bestFitAction(_ sender: Any) {
        sizeToFitMenuItem.state = .on
        sizeToOriginalMenuItem.state = .off
        
        preview?.window?.sizeToFit()
    }

    @IBAction private func originalSizeAction(_ sender: Any) {
        sizeToFitMenuItem.state = .off
        sizeToOriginalMenuItem.state = .on
        
        preview?.window?.sizeToOriginal()
    }

    @IBAction private func betterSpeedAction(_ sender: Any) {
        
    }

    @IBAction private func betterQualityAction(_ sender: Any) {
        
    }

    @IBAction private func autoQualityAction(_ sender: Any) {
        
    }
}
