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
        
        serverPathTextField.text = Settings.shared.server
        
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
        if let path = serverPathTextField.text?.trimmingCharacters(in: CharacterSet(charactersIn: "/")) {
            Settings.shared.server = path
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
