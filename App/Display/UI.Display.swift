//
//  Features.Screen.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 21.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation
import AppKit


fileprivate extension String {
    static let screenLabel: String
        = "Please allow screen recording"
}


fileprivate extension NSStoryboardSegue.Identifier {
    static let mirror: NSStoryboardSegue.Identifier = "DisplayMirrorWindowController"
}


class DisplayCaptureController : CaptureController {
    
    enum Error : Swift.Error {
        case displayMode
    }
    
    @IBOutlet private var inputFPSLabel: NSTextField!
    @IBOutlet private var outputFPSLabel: NSTextField!
    private var displaySelectionController: DisplayPreviewsController?
    private var privacyController: PrivacyViewController?
    private var previewWindowController: DisplayMirrorWindowController?

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let controller = segue.destinationController as? DisplayPreviewsController {
            displaySelectionController = controller
        }
        
        if let controller = segue.destinationController as? PrivacyViewController {
            controller.status = AVDisplayRecordingPrivacyStatus()
            privacyController = controller
        }
        
        if let controller = segue.destinationController as? DisplayMirrorWindowController {
            let screens = NSScreen.screens
            
            if screens.count > 1 {
                controller.window?.setFrame(screens[1].frame, display: true)
            }
            else {
                controller.window?.setFrame(screens[0].frame, display: true)
            }
            
            if let sampleBufferView = controller.viewController?.sampleBufferView {
                self.previewView = sampleBufferView
            }
            
            previewWindowController?.close()
            previewWindowController = controller
        }
    }
    
    override func listenButtonAction(_ sender: Any) {
        self.performSegue(withIdentifier: .mirror, sender: sender)
        super.listenButtonAction(sender)
    }

    override func authorized() -> Bool? {
        return privacyController?.status?.authorized == true
    }
    
    override func requestPermissionsAndWait() {
        privacyController?.requestPermissionsAndWait()
    }

    override func createCaptureSession() throws -> SessionProtocol {
        let displayConfig = try createDisplaysConfigs().first!
        let videoRect = displayConfig.rect
        let videoConfig = VideoConfig(codec: .h264,
                                      fps: CMTime.video(fps: 60),
                                      dimensions: CMVideoDimensions(width: Int32(videoRect.width),
                                                                    height: Int32(videoRect.height)))
        let inputFPS: FuncWithDouble = { fps in
            dispatchMainAsync {
                self.inputFPSLabel.stringValue = "\(Int(fps))"
            }
        }

        let outputFPS: FuncWithDouble = { fps in
            dispatchMainAsync {
                self.outputFPSLabel.stringValue = "\(Int(fps))"
            }
        }

        return try Capture.shared.display(config: (display: displayConfig, video: videoConfig),
                                          inputFPS: inputFPS,
                                          outputFPS: outputFPS, layer: previewView?.sampleLayer)
    }
    
    override func createListenSession() throws -> SessionProtocol {
        let inputFPS: FuncWithDouble = { fps in
            dispatchMainAsync {
                self.inputFPSLabel.stringValue = "\(Int(fps))"
            }
        }

        var result = Capture.shared.preview(preview: previewView?.sampleLayer,
                                            inputFPS: inputFPS)
        
        result = Session(result, start: {
            dispatchMainSync {
                self.previewWindowController?.session = self.activeSession
            }
        }, stop: {
            dispatchMainSync {
                self.previewWindowController?.session = nil
                self.previewWindowController?.close()
            }
        })
        
        return result
    }
    
    private func createDisplaysConfigs() throws -> [DisplayConfig] {
        var result = [DisplayConfig]()
        guard
            let displaySelectionController = displaySelectionController
            else { assert(false); return result }
        
        let displays = displaySelectionController.displays
        let maxColumns = Int(ceil(sqrt(Double(displays.count))))
        var columnIndex = 0
        var origin = CGPoint.zero
        
        for displayID in displaySelectionController.displays {
            guard let displayMode = CGDisplayCopyDisplayMode(displayID) else { throw Error.displayMode }
            let rect = CGRect(x: Int(origin.x),
                              y: Int(origin.y),
                              width: displayMode.pixelWidth,
                              height: displayMode.pixelHeight)
            let displayConfig = DisplayConfig(displayID: displayID, rect: rect)
            
            result.append(displayConfig)
            columnIndex += 1
            origin.x += CGFloat(displayMode.pixelWidth)
            
            if columnIndex >= maxColumns {
                columnIndex = 0
                origin.x += 0
                origin.y += CGFloat(displayMode.pixelHeight)
            }
        }
        
        return result
    }
}
