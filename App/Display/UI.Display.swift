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
    @IBOutlet private(set) var serverPathTextField: NSTextField!
    @IBOutlet private(set) var inputFPSLabel: NSTextField!
    @IBOutlet private(set) var outputFPSLabel: NSTextField!

    @IBOutlet private(set) var setupSenderWebSocketButton: NSButton!
    @IBOutlet private(set) var setupSenderWebSocketACKButton: NSButton!
    @IBOutlet private(set) var setupSenderWebSocketQualityButton: NSButton!

    @IBOutlet private(set) var setupSenderDuplicatesButton: NSButton!
    @IBOutlet private(set) var setupSenderDuplicatesMetalButton: NSButton!
    @IBOutlet private(set) var setupSenderDuplicatesMemcmpButton: NSButton!

    @IBOutlet private(set) var setupEventsButton: NSButton!
    @IBOutlet private(set) var setupDisplayButton: NSButton!
    @IBOutlet private(set) var setupPreviewButton: NSButton!
    @IBOutlet private(set) var setupMultithreadingButton: NSButton!
    
    @IBOutlet private(set) var tableViewTiming1: NSTableView!
    @IBOutlet private(set) var tableViewTiming2: NSTableView!
    @IBOutlet private(set) var tableViewACK1: NSTableView!
    @IBOutlet private(set) var tableViewByterate: NSTableView!

    @IBAction private func networkButtonsAction(_ sender: AnyObject) {}
    @IBAction private func duplicatesButtonsAction(_ sender: AnyObject) {}
    
    func save() {
        Settings.shared.acknowledge = setupSenderWebSocketACKButton.state == .on
        Settings.shared.display     = setupDisplayButton.state == .on
        Settings.shared.duplicates  = setupSenderDuplicatesButton.state == .on
        Settings.shared.events      = setupEventsButton.state == .on
        Settings.shared.memcmp      = setupSenderDuplicatesMemcmpButton.state == .on
        Settings.shared.metal       = setupSenderDuplicatesMetalButton.state == .on
        Settings.shared.multithread = setupMultithreadingButton.state == .on
        Settings.shared.networking  = setupSenderWebSocketButton.state == .on
        Settings.shared.preview     = setupPreviewButton.state == .on
        Settings.shared.server      = serverPathTextField.stringValue
        Settings.shared.stream      = setupSenderWebSocketQualityButton.state == .on
    }
    
    func restore() {
        setupSenderWebSocketACKButton.state     = Settings.shared.acknowledge ? .on : .off
        setupDisplayButton.state                = Settings.shared.display ? .on : .off
        setupSenderDuplicatesButton.state       = Settings.shared.duplicates ? .on : .off
        setupEventsButton.state                 = Settings.shared.events ? .on : .off
        setupSenderDuplicatesMemcmpButton.state = Settings.shared.memcmp ? .on : .off
        setupSenderDuplicatesMetalButton.state  = Settings.shared.metal ? .on : .off
        setupMultithreadingButton.state         = Settings.shared.multithread ? .on : .off
        setupSenderWebSocketButton.state        = Settings.shared.networking ? .on : .off
        setupPreviewButton.state                = Settings.shared.preview ? .on : .off
        serverPathTextField.stringValue         = Settings.shared.server
        setupSenderWebSocketQualityButton.state = Settings.shared.stream ? .on : .off
    }
}


fileprivate class SetupDisplayCapture : VideoSetupVector {
    private let displayConfig: DisplayConfig
    private let encoderConfig: VideoEncoderConfig
    private let views: DisplayCaptureViews
    private let layer: AVSampleBufferDisplayLayer
    private let root: VideoSetupProtocol
    
    init(root: VideoSetupProtocol,
         displayConfig: DisplayConfig,
         encoderConfig: VideoEncoderConfig,
         views: DisplayCaptureViews,
         layer: AVSampleBufferDisplayLayer) {
        self.root = root
        self.displayConfig = displayConfig
        self.encoderConfig = encoderConfig
        self.views = views
        self.layer = layer
        super.init()
    }
    
    override func create() -> [VideoSetupProtocol] {
        let timebase = Timebase(); root.session(timebase, kind: .other)
        let display = DisplaySetup(root: root, settings: displayConfig)
        let displayInfo = DisplaySetup.InfoCapture(root: root, settings: displayConfig)
        let preview = VideoSetupCheckbox(next: VideoSetupPreview(root: root, layer: layer),
                                         checkbox: views.setupPreviewButton)
        let encoder = VideoSetupEncoder(root: root, settings: encoderConfig)
        let deserializer = VideoSetupDeserializerH264(root: root, kind: .serializer)
        let multithreading = VideoSetupCheckbox(next: VideoSetupMultithreading(root: root),
                                                checkbox: views.setupMultithreadingButton)
        let duplicatesMetal = VideoSetupCheckbox(next: VideoSetupDuplicatesMetal(root: root),
                                                 checkbox: views.setupSenderDuplicatesMetalButton)
        let duplicatesMemcmp = VideoSetupCheckbox(next: VideoSetupDuplicatesMemcmp(root: root),
                                                  checkbox: views.setupSenderDuplicatesMemcmpButton)
        let duplicates = VideoSetupCheckbox(next: broadcast([duplicatesMetal, duplicatesMemcmp]) ?? VideoSetup(),
                                            checkbox: views.setupSenderDuplicatesButton)
        let webSocketHelm = VideoSetupCheckbox(next: cast(video: WebSocketMaster.SetupHelm(root: root)),
                                               checkbox: views.setupSenderWebSocketButton)
        let webSocketACKMetric = StringProcessorTableView(tableView: views.tableViewACK1)
        let webSocketACK = VideoSetupCheckbox(
            next: VideoSetupCheckbox(next: VideoSetupSenderACK(root: root, metric: webSocketACKMetric),
                                     checkbox: views.setupSenderWebSocketACKButton),
            checkbox: views.setupSenderWebSocketButton)
            
        let webSocketQuality = VideoSetupCheckbox(
            next: VideoSetupCheckbox(next: VideoSetupSenderQuality(root: root),
                                     checkbox: views.setupSenderWebSocketQualityButton),
            checkbox: views.setupSenderWebSocketButton)
        let captureFPS = VideoSetupMeasure(kind: .capture,
                                           measure: MeasureFPSLabel(label: views.inputFPSLabel))
        let duplicatesFPS = VideoSetupMeasure(kind: .duplicatesFree,
                                              measure: MeasureFPSLabel(label: views.outputFPSLabel))
        
        let byterateString
            = StringProcessorWithIntervalCutting(next: StringProcessorTableView(tableView: views.tableViewByterate))
        let byterateMeasure
            = MeasureByterate(string: byterateString)
        let byterate
            = VideoSetupDataProcessor(data: byterateMeasure, kind: .networkData)

        let timestamp1string
            = StringProcessorWithIntervalBatching(next: StringProcessorTableView(tableView: views.tableViewTiming1))
        let timestamp1processor
            = VideoOutputPresentationTime(string: timestamp1string, timebase: timebase)
        let timestamp1
            = VideoSetupProcessor(video: timestamp1processor, kind: .capture)

        let timestamp2string
            = StringProcessorWithIntervalBatching(next: StringProcessorTableView(tableView: views.tableViewTiming2))
        let timestamp2processor
            = VideoOutputPresentationTime(string: timestamp2string, timebase: timebase)
        let timestamp2
            = VideoSetupProcessor(video: timestamp2processor, kind: .duplicatesFree)

        root.session(Session.DispatchSync(session: broadcast([ byterateString,
                                                               timestamp1string,
                                                               timestamp2string ]) ?? Session(),
                                          queue: DispatchQueue.main), kind: .other)


        return [
            preview,
            encoder,
            deserializer,
            multithreading,
            duplicates,
            webSocketHelm,
            webSocketACK,
            webSocketQuality,
            captureFPS,
            duplicatesFPS,
            byterate,
            timestamp1,
            timestamp2,
            display,
            cast(video: displayInfo) ]
    }
}


fileprivate class SetupVideoListening : VideoSetupVector {
    private let views: DisplayCaptureViews
    private let layer: AVSampleBufferDisplayLayer
    private let root: VideoSetupProtocol

    init(root: VideoSetupProtocol, views: DisplayCaptureViews, layer: AVSampleBufferDisplayLayer) {
        self.root = root
        self.views = views
        self.layer = layer
        super.init()
    }
    
    override func create() -> [VideoSetupProtocol] {
        let preview = VideoSetupPreview(root: root, layer: layer)
        let deserializer = VideoSetupDeserializerH264(root: root, kind: .networkDataOutput)
        let webSocketHelm = VideoSetupCheckbox(next: cast(video: WebSocketSlave.SetupHelm(root: root)),
                                               checkbox: views.setupSenderWebSocketButton)
        let webSocketACK = VideoSetupCheckbox(next: VideoSetupViewerACK(root: root),
                                              checkbox: views.setupSenderWebSocketACKButton)
        let webSocketQuality = VideoSetupCheckbox(next: VideoSetupViewerQuality(root: root),
                                                  checkbox: views.setupSenderWebSocketQualityButton)
        let fps = VideoSetupMeasure(kind: .deserializer,
                                    measure: MeasureFPSLabel(label: views.inputFPSLabel))

        return [
            preview,
            deserializer,
            webSocketHelm,
            webSocketACK,
            webSocketQuality,
            fps ]
    }
}


fileprivate class SetupEventsCapture : EventProcessorSetup.Vector {
    private let root: EventProcessor.Setup
    private let views: DisplayCaptureViews
    private let layer: CALayer

    init(root: EventProcessor.Setup, views: DisplayCaptureViews, layer: CALayer) {
        self.root = root
        self.views = views
        self.layer = layer
        super.init()
    }

    override func create() -> [EventProcessor.Setup] {
        let supportedTypes: NSEvent.EventTypeMask = [
            .keyUp,
            .keyDown,
            .flagsChanged,
            .scrollWheel,
            .mouseMoved,
            .rightMouseUp,
            .rightMouseDown,
            .rightMouseDragged,
            .leftMouseUp,
            .leftMouseDown,
            .leftMouseDragged,
            .otherMouseUp,
            .otherMouseDown,
            .otherMouseDragged ]
        
        let queueGet = DispatchQueue.createEventsGet()
        let transform = EventProcessor.Transform.Setup(root: root, layer: layer)
        let filter = EventProcessor.FilterByMask.Setup(root: root, supportedTypes: supportedTypes)
        var filterWindow: EventProcessor.Setup = EventProcessorSetup.shared
        let filterMouseMove = EventProcessorSetup.FilterMouseMove(root: root, queue: queueGet, interval: 1.0 / 30.0)
        var captureWindow: Session.Setup = SessionSetup.shared
        
        let serializer = EventProcessor.Serializer.Setup(root: root)
        let dispatchCapture = EventProcessor.DispatchAsync.Setup(root: root, queue: queueGet)
        let capture = EventCapture.Setup(root: root)

        if let window = (layer.delegate as? NSView)?.window {
            filterWindow = EventProcessor.FilterByWindow.Setup(root: root, window: window)
            captureWindow = EventCapture.Window.Setup(root: root, window: window)
        }
        
        return [
            serializer,
            filter,
            filterWindow,
            filterMouseMove,
            capture,
            dispatchCapture,
            transform,
            cast(event: captureWindow) ]
    }
}


fileprivate class SetupEventsListening : EventProcessorSetup.Vector {
    private let views: DisplayCaptureViews
    private let root: EventProcessor.Setup

    init(root: EventProcessor.Setup, views: DisplayCaptureViews) {
        self.root = root
        self.views = views
        super.init()
    }
    
    override func create() -> [EventProcessor.Setup] {
        let deserializer = EventProcessor.Deserializer.Setup(root: root)
        let post = EventProcessor.Post.Setup(root: root)

        return [
            deserializer,
            post ]
    }
}


fileprivate class SetupCapture : CaptureSetup.Vector {
    private let displayConfig: DisplayConfig
    private let encoderConfig: VideoEncoderConfig
    private let views: DisplayCaptureViews
    private let layer: AVSampleBufferDisplayLayer
    private let videoRoot = VideoSetupVector()
    private let eventRoot = EventProcessorSetup.Vector()

    init(displayConfig: DisplayConfig,
         encoderConfig: VideoEncoderConfig,
         views: DisplayCaptureViews,
         layer: AVSampleBufferDisplayLayer) {
        self.displayConfig = displayConfig
        self.encoderConfig = encoderConfig
        self.views = views
        self.layer = layer
        super.init()
    }
    
    override func create() -> [CaptureSetup.Proto] {
        let websocket = WebSocketMaster.SetupData(root: self)
        let aggregator = SessionSetup.Aggregator()
        let aggregatorDispatch = SessionSetup.DispatchSync(next: aggregator, queue: Capture.shared.setupQueue)

        videoRoot.register(cast(video: websocket))
        videoRoot.register(cast(video: aggregator))

        eventRoot.register(cast(event: websocket))
        eventRoot.register(cast(event: aggregator))

        var display: VideoSetupProtocol = SetupDisplayCapture(root: videoRoot,
                                                              displayConfig: displayConfig,
                                                              encoderConfig: encoderConfig,
                                                              views: views,
                                                              layer: layer)
        var events: EventProcessor.Setup = SetupEventsListening(root: eventRoot,
                                                                views: views)
        

        display = VideoSetupCheckbox(next: display, checkbox: views.setupDisplayButton)
        events = EventProcessorSetup.Checkbox(next: events, checkbox: views.setupEventsButton)
        
        videoRoot.register(display)
        eventRoot.register(events)

        return [websocket, display, events, cast(capture: aggregatorDispatch)]
    }
}


fileprivate class SetupViewer : CaptureSetup.Vector {
    private let views: DisplayCaptureViews
    private let layer: AVSampleBufferDisplayLayer
    private let videoRoot = VideoSetupVector()
    private let eventRoot = EventProcessorSetup.Vector()

    init(views: DisplayCaptureViews, layer: AVSampleBufferDisplayLayer) {
        self.views = views
        self.layer = layer
        super.init()
    }

    override func create() -> [CaptureSetup.Proto] {
        let aggregator = SessionSetup.Aggregator()
        let aggregatorDispatch = SessionSetup.DispatchSync(next: aggregator, queue: Capture.shared.setupQueue)
        let websocket = WebSocketSlave.SetupData(root: self)
        var video: VideoSetupProtocol = SetupVideoListening(root: videoRoot, views: views, layer: layer)
        var events: EventProcessor.Setup = SetupEventsCapture(root: eventRoot, views: views, layer: layer)

        video = VideoSetupCheckbox(next: video, checkbox: views.setupDisplayButton)
        events = EventProcessorSetup.Checkbox(next: events, checkbox: views.setupEventsButton)
        
        videoRoot.register(video)
        videoRoot.register(cast(video: websocket))
        videoRoot.register(cast(video: aggregator))

        eventRoot.register(events)
        eventRoot.register(cast(event: websocket))
        eventRoot.register(cast(event: aggregator))

        return [websocket, video, events, cast(capture: aggregatorDispatch)]
    }
}


class DisplayCaptureController : CaptureController {
    
    enum Error : Swift.Error {
        case displayMode
    }
    
    @IBOutlet private var displayCaptureViews: DisplayCaptureViews!
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
    
    override func createCaptureSession() throws -> SessionProtocol {
        let displayConfig = try createDisplaysConfigs().first!
        let videoRect = displayConfig.rect
        let dimensions = CMVideoDimensions(width: Int32(videoRect.width), height: Int32(videoRect.height))
        let encoderConfig = VideoEncoderConfig(codec: .h264, input: dimensions, output: dimensions)
        let layer = previewView?.sampleLayer ?? AVSampleBufferDisplayLayer()

        return SetupCapture(displayConfig: displayConfig,
                            encoderConfig: encoderConfig,
                            views: displayCaptureViews,
                            layer: layer).setup() ?? Session.shared
    }
    
    override func createListenSession() throws -> SessionProtocol {
        let layer = previewView?.sampleLayer ?? AVSampleBufferDisplayLayer()
        var result: Session.Proto = SetupViewer(views: displayCaptureViews, layer: layer).setup() ?? Session.shared
        
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
