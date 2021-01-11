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
        = Bundle.main.bundleIdentifier!.appending(".CaptureIOS-Upload-Extension")
}

class ViewController: UIViewController {

    private var broadcastController: RPBroadcastActivityViewController?
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
        else {
            RPBroadcastActivityViewController.load { (controller: RPBroadcastActivityViewController?, error: Error?) in
                self.broadcastController = controller
                self.broadcastController?.delegate = self
                self.present(self.broadcastController!, animated: true, completion: nil)
            }
        }
    }
}

extension ViewController {
    @available(iOS 12.0, *)
    func setupPickerView() {
        // Swap the button for an RPSystemBroadcastPickerView.
        // iOS 13.0 throws an NSInvalidArgumentException when RPSystemBroadcastPickerView is used to start a broadcast.
        // https://stackoverflow.com/questions/57163212/get-nsinvalidargumentexception-when-trying-to-present-rpsystembroadcastpickervie
        if #available(iOS 13.0, *) {
            // The issue is resolved in iOS 13.1.
            if #available(iOS 13.1, *) {
            } else {
                broadcastButton?.addTarget(self, action: #selector(tapBroadcastPickeriOS13(sender:)), for: UIControl.Event.touchUpInside)
                return
            }
        }

//        let broadcastPickerView = RPSystemBroadcastPickerView(frame: CGRect(x: 0,
//                                                                   y: 0,
//                                                                   width: view.bounds.width,
//                                                                   height: 120))
        broadcastPickerView.translatesAutoresizingMaskIntoConstraints = false
        broadcastPickerView.showsMicrophoneButton = false
        broadcastPickerView.preferredExtension = .broadcastExtensionSetupUIbundleID

        // Theme the picker view to match the white that we want.
        if let button = broadcastPickerView.subviews.first as? UIButton {
            button.imageView?.tintColor = UIColor.red
        }

//        view.addSubview(broadcastPickerView)
//
//        self.broadcastPickerView = broadcastPickerView
//        broadcastButton?.isEnabled = false
//        broadcastButton?.titleEdgeInsets = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
//
//        let centerX = NSLayoutConstraint(item:broadcastPickerView,
//                                         attribute: NSLayoutConstraint.Attribute.centerX,
//                                         relatedBy: NSLayoutConstraint.Relation.equal,
//                                         toItem: broadcastButton,
//                                         attribute: NSLayoutConstraint.Attribute.centerX,
//                                         multiplier: 1,
//                                         constant: 0);
//        self.view.addConstraint(centerX)
//        let centerY = NSLayoutConstraint(item: broadcastPickerView,
//                                         attribute: NSLayoutConstraint.Attribute.centerY,
//                                         relatedBy: NSLayoutConstraint.Relation.equal,
//                                         toItem: broadcastButton,
//                                         attribute: NSLayoutConstraint.Attribute.centerY,
//                                         multiplier: 1,
//                                         constant: -10);
//        self.view.addConstraint(centerY)
//        let width = NSLayoutConstraint(item: broadcastPickerView,
//                                       attribute: NSLayoutConstraint.Attribute.width,
//                                       relatedBy: NSLayoutConstraint.Relation.equal,
//                                       toItem: self.broadcastButton,
//                                       attribute: NSLayoutConstraint.Attribute.width,
//                                       multiplier: 1,
//                                       constant: 0);
//        self.view.addConstraint(width)
//        let height = NSLayoutConstraint(item: broadcastPickerView,
//                                        attribute: NSLayoutConstraint.Attribute.height,
//                                        relatedBy: NSLayoutConstraint.Relation.equal,
//                                        toItem: self.broadcastButton,
//                                        attribute: NSLayoutConstraint.Attribute.height,
//                                        multiplier: 1,
//                                        constant: 0);
//        self.view.addConstraint(height)
    }
    
    @objc func tapBroadcastPickeriOS13(sender: UIButton) {
        let message = "ReplayKit broadcasts can not be started using the broadcast picker on iOS 13.0. Please upgrade to iOS 13.1+, or start a broadcast from the screen recording widget in control center instead."
        let alertController = UIAlertController(title: "Start Broadcast", message: message, preferredStyle: .actionSheet)

        let settingsButton = UIAlertAction(title: "Launch Settings App", style: .default, handler: { (action) -> Void in
            // Launch the settings app, with control center if possible.
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:]) { (success) in
            }
        })

        alertController.addAction(settingsButton)

        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sender
            alertController.popoverPresentationController?.sourceRect = sender.bounds
        } else {
            // Adding the cancel action
            let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            })
            alertController.addAction(cancelButton)
        }
        self.navigationController!.present(alertController, animated: true, completion: nil)
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

extension ViewController : RPBroadcastActivityViewControllerDelegate {
    func broadcastActivityViewController(
        _ broadcastActivityViewController: RPBroadcastActivityViewController,
        didFinishWith broadcastController: RPBroadcastController?, error: Error?) {
    }
}
