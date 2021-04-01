//
//  ViewController.swift
//  Application
//
//  Created by Ivan Kh on 15.02.2021.
//

import Cocoa


fileprivate extension NSStoryboardSegue.Identifier {
    static let previewSegue = "PreviewSegue"
    static let combinedPreviewSegue = "CombinedPreviewSegue"
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
            modeCombineButton.state = .on
        }
        else if Settings.shared.modeCombine == false {
            modeSplitButton.state = .on
        }
        else if NSScreen.screens.count > 1 {
            modeSplitButton.state = .on
        }
        else {
            modeCombineButton.state = .on
        }
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

    @IBAction fileprivate func clearFileAction1(_ sender: SelectFileButton) {
        clearFile(button: sender, settingKey: .fileURL1, index: 0)
    }

    @IBAction fileprivate func clearFileAction2(_ sender: SelectFileButton) {
        clearFile(button: sender, settingKey: .fileURL2, index: 1)
    }

    @IBAction fileprivate func clearFileAction3(_ sender: SelectFileButton) {
        clearFile(button: sender, settingKey: .fileURL3, index: 2)
    }

    @IBAction fileprivate func clearFileAction4(_ sender: SelectFileButton) {
        clearFile(button: sender, settingKey: .fileURL4, index: 3)
    }

    @IBAction @objc func viewerAction(_ sender: Any) {
        guard NSScreen.screens.count > 0 else { return }
        
        let urls = self.urls.reduce([URL]()) {
            if let url = $1 {
                return $0 + [ url ]
            }
            else {
                return $0
            }
        }
        
        if modeCombineButton.state == .on {
            self.performSegue(withIdentifier: urls.count > 1 ? .combinedPreviewSegue : .previewSegue,
                              sender: PreviewObject(index: 0, urls: urls))
            return
        }
        
        for index in 0 ..< urls.count {
            if index < NSScreen.screens.count - 1 {
                self.performSegue(withIdentifier: .previewSegue,
                                  sender: PreviewObject(index: index, urls: [ urls[index] ]))
            }
            else {
                let urlsLeft = Array(urls.suffix(from: index))
                self.performSegue(withIdentifier: urlsLeft.count > 1 ? .combinedPreviewSegue : .previewSegue,
                                  sender: PreviewObject(index: index, urls: urlsLeft))
                break
            }
        }
    }
    
    @IBAction @objc func cancelAction(_ sender: Any) {
        let sessions = self.sessions
        
        self.sessions.removeAll()
        sessions.forEach { $0.stop() }
    }
    
    @IBAction @objc func modeButtonAction(_ sender: NSButton) {
        if sender == modeCombineButton && modeCombineButton.state == .on {
            Settings.shared.modeCombine = true
        }
        else if sender == modeSplitButton && modeSplitButton.state == .on {
            Settings.shared.modeCombine = false
        }
    }

    private func clearFile(button: SelectFileButton, settingKey: String, index: Int) {
        self.urls[index] = nil
        Settings.shared.writeSetting(settingKey, nil)
        button.textField.stringValue = ""
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
}

