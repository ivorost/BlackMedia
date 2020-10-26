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


class DisplayCaptureController : CaptureController {
    
    enum Error : Swift.Error {
        case displayMode
    }
    
    @IBOutlet private var screenPreviewTemplate: DisplayPreviewView!
    @IBOutlet private var fpsLabel: NSTextField!
    private var DisplayPreviewsController: DisplayPreviewsController?
    private var privacyController: PrivacyViewController?

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let controller = segue.destinationController as? DisplayPreviewsController {
            DisplayPreviewsController = controller
        }
        
        if let controller = segue.destinationController as? PrivacyViewController {
            controller.status = AVDisplayRecordingPrivacyStatus()
            privacyController = controller
        }
    }

    override func folderURL() -> URL? {
        return URL.captureScreen
    }

    override func fileExtension() -> String {
        return "mov"
    }

    override func authorized() -> Bool? {
        return privacyController?.status?.authorized == true
    }
    
    override func requestPermissionsAndWait() {
        privacyController?.requestPermissionsAndWait()
    }

    override func createSession(url: URL) throws -> (session: SessionProtocol, progress: CaptureProgress?) {
        let displaysConfigs = try createDisplaysConfigs()
        let videoRect = displaysConfigs.map{ $0.rect }.union()
        let videoConfig = VideoConfig(codec: .h264,
                                      fps: CMTime.video(fps: 60),
                                      dimensions: CMVideoDimensions(width: Int32(videoRect.width),
                                                                    height: Int32(videoRect.height)))
        let fps: FuncWithDouble = { fps in
            dispatchMainAsync {
                self.fpsLabel.stringValue = "\(Int(fps))"
            }
        }

        var progress: CaptureProgress?
        let session = try Capture.shared.display(config: (file: .mov, displays: displaysConfigs, video: videoConfig),
                                                 preview: previewView.captureLayer,
                                                 output: url,
                                                 progress: &progress,
                                                 fps: fps)
        
        return (session: session, progress: progress)
    }
    
    private func createDisplaysConfigs() throws -> [DisplayConfig] {
        var result = [DisplayConfig]()
        guard let DisplayPreviewsController = DisplayPreviewsController else { assert(false); return result }
        
        let displays = DisplayPreviewsController.displays
        let maxColumns = Int(ceil(sqrt(Double(displays.count))))
        var columnIndex = 0
        var origin = CGPoint.zero
        
        for displayID in DisplayPreviewsController.displays {
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
