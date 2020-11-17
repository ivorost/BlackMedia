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


class DisplayCaptureViews : NSObject {
    @IBOutlet private(set) var inputFPSLabel: NSTextField!
    @IBOutlet private(set) var outputFPSLabel: NSTextField!

    @IBOutlet private(set) var setupSenderWebSocketButton: NSButton!
    @IBOutlet private(set) var setupSenderWebSocketACKButton: NSButton!
    @IBOutlet private(set) var setupSenderWebSocketQualityButton: NSButton!

    @IBOutlet private(set) var setupSenderDuplicatesButton: NSButton!
    @IBOutlet private(set) var setupSenderDuplicatesMetalButton: NSButton!
    @IBOutlet private(set) var setupSenderDuplicatesMemcmpButton: NSButton!

    @IBOutlet private(set) var setupSenderPreviewButton: NSButton!
    @IBOutlet private(set) var setupSenderMultithreadingButton: NSButton!
    
    @IBAction private func networkButtonsAction(_ sender: AnyObject) {
        
    }

    @IBAction private func duplicatesButtonsAction(_ sender: AnyObject) {
        
    }
}


fileprivate class CaptureSetup : VideoSetupVector {
    private let views: DisplayCaptureViews
    private let encoderConfig: VideoEncoderConfig
    private let layer: AVSampleBufferDisplayLayer
    
    init(views: DisplayCaptureViews, encoderConfig: VideoEncoderConfig, layer: AVSampleBufferDisplayLayer) {
        self.views = views
        self.encoderConfig = encoderConfig
        self.layer = layer
        super.init()
    }
    
    override func create() -> [VideoSetupProtocol] {
        let root = self
        let general = VideoSetupGeneral()
        let preview = VideoSetupCheckbox(next: VideoSetupPreview(root: root, layer: layer),
                                         checkbox: views.setupSenderPreviewButton)
        let encoder = VideoSetupEncoder(root: root, settings: encoderConfig)
        let deserializer = VideoSetupDeserializerH264(root: root, kind: .serializer)
        let multithreading = VideoSetupCheckbox(next: VideoSetupMultithreading(root: root),
                                                checkbox: views.setupSenderMultithreadingButton)
        let duplicatesMetal = VideoSetupCheckbox(next: VideoSetupDuplicatesMetal(root: root),
                                                 checkbox: views.setupSenderDuplicatesMetalButton)
        let duplicatesMemcmp = VideoSetupCheckbox(next: VideoSetupDuplicatesMemcmp(root: root),
                                                  checkbox: views.setupSenderDuplicatesMemcmpButton)
        let duplicates = VideoSetupCheckbox(next: broadcast([duplicatesMetal, duplicatesMemcmp]) ?? VideoSetup(),
                                            checkbox: views.setupSenderDuplicatesButton)
        let webSocket = VideoSetupCheckbox(next: VideoSetupWebSocketSender(root: root),
                                           checkbox: views.setupSenderWebSocketButton)
        let webSocketACK = VideoSetupCheckbox(next: VideoSetupSenderACK(root: root),
                                              checkbox: views.setupSenderWebSocketACKButton)
        let webSocketQuality = VideoSetupCheckbox(next: VideoSetupSenderQuality(root: root),
                                                  checkbox: views.setupSenderWebSocketQualityButton)
        let captureFPS = VideoSetupMeasure(kind: .capture,
                                           measure: MeasureFPSLabel(label: views.inputFPSLabel))
        let duplicatesFPS = VideoSetupMeasure(kind: .duplicatesFree,
                                              measure: MeasureFPSLabel(label: views.outputFPSLabel))

        return [
            general,
            preview,
            encoder,
            deserializer,
            multithreading,
            duplicates,
            webSocket,
            webSocketACK,
            webSocketQuality,
            captureFPS,
            duplicatesFPS ]
    }
}


fileprivate class ListenerSetup : VideoSetupVector {
    private let views: DisplayCaptureViews
    private let layer: AVSampleBufferDisplayLayer

    init(views: DisplayCaptureViews, layer: AVSampleBufferDisplayLayer) {
        self.views = views
        self.layer = layer
        super.init()
    }
    
    override func create() -> [VideoSetupProtocol] {
        let root = self
        let general = VideoSetupGeneral()
        let preview = VideoSetupPreview(root: root, layer: layer)
        let deserializer = VideoSetupDeserializerH264(root: root, kind: .networkData)
        let webSocketACK = VideoSetupCheckbox(next: VideoSetupViewerACK(root: root),
                                              checkbox: views.setupSenderWebSocketACKButton)
        let webSocketQuality = VideoSetupCheckbox(next: VideoSetupViewerQualityControl(root: root),
                                                  checkbox: views.setupSenderWebSocketQualityButton)
        let fps = VideoSetupMeasure(kind: .deserializer,
                                    measure: MeasureFPSLabel(label: views.inputFPSLabel))

        return [
            general,
            preview,
            deserializer,
            webSocketACK,
            webSocketQuality,
            fps ]
    }
}


class DisplayCaptureController : CaptureController {
    
    enum Error : Swift.Error {
        case displayMode
    }
    
    @IBOutlet private var displayCaptureViews: DisplayCaptureViews!
    private var privacyController: PrivacyViewController?
    private var previewWindowController: DisplayMirrorWindowController?

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

    override func createCaptureSession() throws -> SessionProtocol {
        let displayConfig = try createDisplaysConfigs().first!
        let videoRect = displayConfig.rect
        let dimensions = CMVideoDimensions(width: Int32(videoRect.width), height: Int32(videoRect.height))
        let encoderConfig = VideoEncoderConfig(codec: .h264, input: dimensions, output: dimensions)
        let layer = previewView?.sampleLayer ?? AVSampleBufferDisplayLayer()

        let setup = CaptureSetup(views: displayCaptureViews, encoderConfig: encoderConfig, layer: layer)
        let display = DisplaySetup(settings: displayConfig, setup: setup)

        return display.setup()
    }
    
    override func createListenSession() throws -> SessionProtocol {
        let layer = previewView?.sampleLayer ?? AVSampleBufferDisplayLayer()
        let setup = ListenerSetup(views: displayCaptureViews, layer: layer)
        let webSocket = VideoSetupWebSocketViewer(root: setup)
        var result = webSocket.setup()
        
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

//    override func createCaptureSession() throws -> SessionProtocol {
//        let displayConfig = try createDisplaysConfigs().first!
//        let videoRect = displayConfig.rect
//        let dimensions = CMVideoDimensions(width: Int32(videoRect.width), height: Int32(videoRect.height))
//        let encoderConfig = VideoEncoderConfig(codec: .h264, input: dimensions, output: dimensions)
//        let inputFPS: FuncWithDouble = { fps in
//            dispatchMainAsync {
//                self.inputFPSLabel.stringValue = "\(Int(fps))"
//            }
//        }
//
//        let outputFPS: FuncWithDouble = { fps in
//            dispatchMainAsync {
//                self.outputFPSLabel.stringValue = "\(Int(fps))"
//            }
//        }
//
//        return Capture.shared.display(displaySettings: displayConfig, encoderSettings: encoderConfig)
//
////        return try Capture.shared.display(config: (display: displayConfig, video: videoConfig),
////                                          inputFPS: inputFPS,
////                                          outputFPS: outputFPS, layer: previewView?.sampleLayer)
//    }
    
//    override func createListenSession() throws -> SessionProtocol {
//        let inputFPS: FuncWithDouble = { fps in
//            dispatchMainAsync {
//                self.inputFPSLabel.stringValue = "\(Int(fps))"
//            }
//        }
//
//        var result = Capture.shared.preview(preview: previewView?.sampleLayer,
//                                            inputFPS: inputFPS)
//
//        result = Session(result, start: {
//            dispatchMainSync {
//                self.previewWindowController?.session = self.activeSession
//            }
//        }, stop: {
//            dispatchMainSync {
//                self.previewWindowController?.session = nil
//                self.previewWindowController?.close()
//            }
//        })
//
//        return result
//    }
  
    private func createDisplaysConfigs() throws -> [DisplayConfig] {
        var result = [DisplayConfig]()
        
        let displays = [CGMainDisplayID()]
        let maxColumns = Int(ceil(sqrt(Double(displays.count))))
        var columnIndex = 0
        var origin = CGPoint.zero
        
        for displayID in displays {
            guard let displayMode = CGDisplayCopyDisplayMode(displayID) else { throw Error.displayMode }
            let rect = CGRect(x: Int(origin.x),
                              y: Int(origin.y),
                              width: displayMode.pixelWidth,
                              height: displayMode.pixelHeight)
            let displayConfig = DisplayConfig(displayID: displayID, rect: rect, fps: CMTime.video(fps: 60))
            
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
