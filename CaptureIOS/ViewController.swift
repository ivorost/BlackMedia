//
//  ViewController.swift
//  CaptureIOS
//
//  Created by Ivan Kh on 17.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import UIKit
import ReplayKit

fileprivate extension String {
    static let broadcastExtensionSetupUIbundleID
        = Bundle.main.bundleIdentifier!.appending(".extension-upload")
}

class ViewController: UIViewController {

    @IBOutlet fileprivate weak var broadcastButton: UIButton?
    @IBOutlet weak var broadcastPickerView: RPSystemBroadcastPickerView!
    @IBOutlet weak var serverPathTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let path = UserDefaults(suiteName: "group.com.idrive.screentest")?.string(forKey: "server_path") {
            serverPathTextField.text = path
        }
        
        if #available(iOS 12.0, *) {
            setupPickerView()
        }
    }
}

extension ViewController {
    @available(iOS 12.0, *)
    func setupPickerView() {
        broadcastPickerView.translatesAutoresizingMaskIntoConstraints = false
        broadcastPickerView.showsMicrophoneButton = false
        broadcastPickerView.preferredExtension = .broadcastExtensionSetupUIbundleID

        // Theme the picker view to match the white that we want.
        if let button = broadcastPickerView.subviews.first as? UIButton {
            button.imageView?.tintColor = UIColor.red
        }
    }
}


extension ViewController : UITextFieldDelegate {
    @IBAction func serverPathEditingDidEnd(_ sender: Any) {
        let path = serverPathTextField.text?.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        UserDefaults(suiteName: "group.com.idrive.screentest")?.set(path, forKey: "server_path")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
