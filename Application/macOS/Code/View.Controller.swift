//
//  ViewController.swift
//  Application
//
//  Created by Ivan Kh on 15.02.2021.
//

import Cocoa

class ViewController: NSViewController {

    private(set) var url: URL?
    @IBOutlet private var filePathTextField: NSTextField!
    @IBOutlet private var errorLabel: NSTextField!
    @IBOutlet private var viewerButton: NSButton!
    @IBOutlet private var cancelButton: NSButton!

    var previewWindow: NSWindow?
    var session: Session.Proto? {
        didSet {
            viewerButton.isEnabled = session == nil
            cancelButton.isEnabled = !viewerButton.isEnabled
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.url = Settings.shared.fileURL
        filePathTextField.stringValue = self.url?.path ?? ""
    }
    
    func show(error: Error?) {
        errorLabel.isHidden = false
    }

    @IBAction func selectFileAction(_ sender: Any) {
        let openPanel = NSOpenPanel()

        if openPanel.runModal() == .OK {
            self.url = openPanel.url
            
            if let url = openPanel.url {
                Settings.shared.fileURL = url
                filePathTextField.stringValue = url.path
                errorLabel.isHidden = true
            }
        }
    }
    
    @IBAction @objc func cancelAction(_ sender: Any) {
        previewWindow?.close()
        session?.stop()
    }
}

