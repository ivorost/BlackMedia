//
//  Features.Permissions.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 04.06.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AppKit

// To reset Privacy settings use:
// tccutil reset Camera
// tccutil reset Microphone
// ...
// or just change app identifier

fileprivate extension URL {
    static let settingsSecurity: URL = URL(fileURLWithPath:
        "/System/Library/PreferencePanes/Security.prefPane")
}


protocol PrivacyStatus {
    var defined: Bool? { get }
    var authorized: Bool? { get }
    var panePath: String { get }
    func request(callback: Func?)
}


class PrivacyViewController : NSViewController {
    
    @IBOutlet private var label: NSTextField!
    var status: PrivacyStatus?
    var defined: Func?
    var requestPermissionsOnViewDidLoad = false
    private var cancelRequest = false
    private var requestTimer: Timer?
    
    var labelView: NSTextField! {
        _ = view
        return label
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadRequestPermissions()
    }
    
    func viewDidLoadRequestPermissions() {
        if !requestPermissionsOnViewDidLoad || !requestPermissionsIfNotDefined() {
            updateViewVisibility()
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        cancelRequest = true
    }
    
    @IBAction private func systemPreferencesButtonAction(_ sender: Any) {
        var url = URL.settingsSecurity
        
        if let panePath = status?.panePath,
            let paneURL = URL(string: panePath) {
            url = paneURL
        }
        
        NSWorkspace.shared.open(url)
    }
    
    func requestPermissions(callback: Func? = nil) {
        guard
            status?.authorized != true, status?.defined != true
            else { callback?(); return }
        
        dispatchMainSync {
            self.view.isHidden = true
        }
        
        self.status?.request {
            callback?()
            
            if self.status?.authorized != true {
                dispatchMainSync {
                    self.updateViewVisibility()
                }
            }
        }
        
        if status?.defined != true {
            dispatchMainSync {
                self.requestTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                                         target: self,
                                                         selector: #selector(updatePrivacyDefined),
                                                         userInfo: nil,
                                                         repeats: true)
            }
        }
    }
    
    @discardableResult func requestPermissionsIfNotDefined(callback: Func? = nil) -> Bool {
        guard status?.defined != true else { return false }
        requestPermissions(callback: callback)
        return true
    }
    
    func requestPermissionsAndWait() {
        var processed = false
        
        requestPermissions {
            processed = true
        }
        
        while !processed {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        }
    }
    
    @objc private func updatePrivacyDefined() {
        guard status?.defined == true else { return }
        
        requestTimer?.invalidate()
        requestTimer = nil
        updateViewVisibility()
        defined?()
    }
    
    private func updateViewVisibility() {
        view.isHidden = status?.defined == false || status?.authorized == true
    }
}

