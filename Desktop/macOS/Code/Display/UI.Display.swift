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
    static let screenLabel = "Please allow screen recording"
}


fileprivate extension NSStoryboardSegue.Identifier {
    static let mirror: NSStoryboardSegue.Identifier = "DisplayMirrorWindowController"
}


class DisplayCaptureController : CaptureController {
    
    enum Error : Swift.Error {
        case displayMode
    }
    
    @IBOutlet private var displayCaptureViews: Video.ScreenCaptureViews!
    @IBOutlet private var networkTestViews: Network.TestView!
    private var privacyController: PrivacyViewController?
    private var previewWindowController: DisplayMirrorWindowController?

    override func viewDidLoad() {
        super.viewDidLoad()
        displayCaptureViews.restore()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
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

    override func start(createSession: @escaping FuncReturningSessionThrowing) {
        displayCaptureViews.save()
        super.start(createSession: createSession)
    }
    
    override func createCaptureSession() throws -> Session.Proto {
        let displayConfig = try createDisplaysConfigs().first!
        let videoRect = displayConfig.rect
        let dimensions = CMVideoDimensions(width: Int32(videoRect.width), height: Int32(videoRect.height))
        let encoderConfig = Video.EncoderConfig(codec: .h264, input: dimensions, output: dimensions)
        let layer = previewView?.sampleLayer ?? AVSampleBufferDisplayLayer()

        return RemoteDesktop.Setup.Sender(displayConfig: displayConfig,
                                          encoderConfig: encoderConfig,
                                          views: displayCaptureViews,
                                          layer: layer).setup() ?? Session.shared
    }
    
    override func createListenSession() throws -> Session.Proto {
        let layer = previewView?.sampleLayer ?? SampleBufferDisplayLayer()
        var result: Session.Proto = RemoteDesktop.Setup.Receiver(views: displayCaptureViews,
                                                                 layer: layer).setup() ?? Session.shared

        result = Session.Base(result, start: {
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

    private func createDisplaysConfigs() throws -> [Video.ScreenConfig] {
        var result = [Video.ScreenConfig]()
        let displays = [CGMainDisplayID()]
        let maxColumns = Int(ceil(sqrt(Double(displays.count))))
        var columnIndex = 0
        var origin = CGPoint.zero
        
        for displayID in displays {
            guard
                let displayConfig = Video.ScreenConfig(displayID: displayID, fps: CMTime.video(fps: 60))
                else { throw Error.displayMode }
            
            result.append(displayConfig)
            columnIndex += 1
            origin.x += CGFloat(displayConfig.rect.width * displayConfig.scale)
            
            if columnIndex >= maxColumns {
                columnIndex = 0
                origin.x += 0
                origin.y += CGFloat(displayConfig.rect.height * displayConfig.scale)
            }
        }
        
        return result
    }
}
