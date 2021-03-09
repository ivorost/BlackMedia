//
//  ViewController.swift
//  Application
//
//  Created by Ivan Kh on 15.02.2021.
//

import Cocoa


fileprivate extension NSStoryboardSegue.Identifier {
    static let previewSegue = "PreviewSegue"
}


@objc class SelectFileButton : NSButton {
    @IBOutlet var textField: NSTextField!
}


class ViewController: NSViewController {

    private var urls = [URL?](repeating: nil, count: 4)
    private var sessions = [Session.Proto]()

    @IBOutlet private var filePathTextField1: NSTextField!
    @IBOutlet private var filePathTextField2: NSTextField!
    @IBOutlet private var filePathTextField3: NSTextField!
    @IBOutlet private var filePathTextField4: NSTextField!
    @IBOutlet private var filePathButton1: NSButton!
    @IBOutlet private var filePathButton2: NSButton!
    @IBOutlet private var filePathButton3: NSButton!
    @IBOutlet private var filePathButton4: NSButton!
    @IBOutlet private var errorLabel: NSTextField!
    @IBOutlet private var viewerButton: NSButton!
    @IBOutlet private var cancelButton: NSButton!
    @IBOutlet private var modeSplitButton: NSButton!
    @IBOutlet private var modeCombineButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let loadURL = { (url: URL?, textField: NSTextField, index: Int) in
            self.urls[index] = url

            if let url = url {
                textField.stringValue = url.path
            }
            else {
                textField.stringValue = ""
            }
        }
        
        loadURL(Settings.shared.fileURL1, filePathTextField1, 0)
        loadURL(Settings.shared.fileURL2, filePathTextField2, 1)
        loadURL(Settings.shared.fileURL3, filePathTextField3, 2)
        loadURL(Settings.shared.fileURL4, filePathTextField4, 3)
        
        if Settings.shared.modeCombine == true {
//            modeCombineButton.state = .on
            modeSplitButton.state = .on
        }
        else if Settings.shared.modeCombine == false {
            modeSplitButton.state = .on
        }
        else if NSScreen.screens.count > 1 {
            modeSplitButton.state = .on
        }
        else {
            modeSplitButton.state = .on
//            modeCombineButton.state = .on
        }
        
        modeDidChanged()
  
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(modeDidChanged),
                                               name: NSApplication.didChangeScreenParametersNotification,
                                               object: nil)
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let controller = segue.destinationController as? PreviewWindowController {
            controller.object = sender as? PreviewObject
        }
    }

    func add(_ session: Session.Proto) {
        sessions.append(session)
        sessionsDidChanged()
    }
    
    func remove(_ session: Session.Proto) {
        _ = sessions.removeFirst { $0 === session }
        sessionsDidChanged()
    }
        
    func show(error: Error?) {
        errorLabel.isHidden = false
    }

    @IBAction fileprivate func selectFileAction1(_ sender: SelectFileButton) {
        selectFile(button: sender, settingKey: .fileURL1, index: 0)
    }

    @IBAction fileprivate func selectFileAction2(_ sender: SelectFileButton) {
        selectFile(button: sender, settingKey: .fileURL2, index: 1)
    }

    @IBAction fileprivate func selectFileAction3(_ sender: SelectFileButton) {
        selectFile(button: sender, settingKey: .fileURL3, index: 2)
    }

    @IBAction fileprivate func selectFileAction4(_ sender: SelectFileButton) {
        selectFile(button: sender, settingKey: .fileURL4, index: 3)
    }

    @IBAction @objc func viewerAction(_ sender: Any) {
        for index in 0 ..< urls.count {
            guard let url = urls[index] else { continue }
            guard index < NSScreen.screens.count else { continue }
            
            self.performSegue(withIdentifier: .previewSegue, sender: PreviewObject(index: index, url: url))
        }
    }
    
    @IBAction @objc func cancelAction(_ sender: Any) {
        let sessions = self.sessions
        
        self.sessions.removeAll()
        sessions.forEach { $0.stop() }
    }
    
    @IBAction @objc func modeButtonAction(_ sender: NSButton) {
        modeDidChanged()
        
        if sender == modeCombineButton && modeCombineButton.state == .on {
            Settings.shared.modeCombine = true
        }
        else if sender == modeSplitButton && modeSplitButton.state == .on {
            Settings.shared.modeCombine = false
        }
    }
    
    private func selectFile(button: SelectFileButton, settingKey: String, index: Int) {
        let openPanel = NSOpenPanel()

        if openPanel.runModal() == .OK {
            self.urls[index] = openPanel.url
            
            if let url = openPanel.url {
                Settings.shared.writeSetting(settingKey, url)
                button.textField.stringValue = url.path
                errorLabel.isHidden = true
            }
        }
    }
    
    private func sessionsDidChanged() {
        viewerButton.isEnabled = sessions.count == 0
        cancelButton.isEnabled = !viewerButton.isEnabled
    }

    @objc private func modeDidChanged() {
        if modeCombineButton.state == .on {
            filePathTextField1.isEnabled = true
            filePathTextField2.isEnabled = true
            filePathTextField3.isEnabled = true
            filePathTextField4.isEnabled = true
            filePathButton1.isEnabled = true
            filePathButton2.isEnabled = true
            filePathButton3.isEnabled = true
            filePathButton4.isEnabled = true
        }
        else {
            filePathTextField1.isEnabled = NSScreen.screens.count > 0
            filePathTextField2.isEnabled = NSScreen.screens.count > 1
            filePathTextField3.isEnabled = NSScreen.screens.count > 2
            filePathTextField4.isEnabled = NSScreen.screens.count > 3
            filePathButton1.isEnabled = NSScreen.screens.count > 0
            filePathButton2.isEnabled = NSScreen.screens.count > 1
            filePathButton3.isEnabled = NSScreen.screens.count > 2
            filePathButton4.isEnabled = NSScreen.screens.count > 3
        }
    }
}

