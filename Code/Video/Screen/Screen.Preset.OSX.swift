//
//  Screen.Preset.swift
//  Core
//
//  Created by Ivan Kh on 30.03.2022.
//


#if os(OSX)
import AVFoundation
import Cocoa
#endif
import BlackUtils

#if os(OSX)
public extension Video.Setup {
    class ScreenCapture : Vector {
        private let displayConfig: Video.ScreenConfig
        private let encoderConfig: Video.EncoderConfig
        private let view: View
        private let layer: AVSampleBufferDisplayLayer
        private let root: Proto
        private let encoderOutputQueue = OperationQueue()
        private let url: URL
        
        public init(root: Proto,
                    url: URL,
                    displayConfig: Video.ScreenConfig,
                    encoderConfig: Video.EncoderConfig,
                    view: View,
                    layer: AVSampleBufferDisplayLayer) {
            self.root = root
            self.url = url
            self.displayConfig = displayConfig
            self.encoderConfig = encoderConfig
            self.view = view
            self.layer = layer
            self.encoderOutputQueue.maxConcurrentOperationCount = 3
            super.init()
        }
        
        public override func create() -> [Proto] {
            let wsSenderHelm = url
            guard let input = AVCaptureScreenInput(settings: displayConfig) else { assertionFailure(); return [] }

            let timebase = BlackMedia.Capture.Timebase(); root.session(timebase, kind: .other)
            let capture = Video.Setup.Input(root: root, session: AVCaptureSession(), input: input)
            let displayInfo = BlackMedia.Capture.Setup.ScreenConfigSerializer(root: root, settings: displayConfig)
            let preview = Checkbox(next: Display(root: root, layer: layer, kind: .deserializer),
                                   checkbox: view.setupPreviewButton)
            let encoder = EncoderH264(root: root, settings: encoderConfig)
            let serializer = SerializerH264(root: root, kind: .encoder)
            let deserializer = DeserializerH264(root: root, kind: .serializer)
            let multithreading = Checkbox(next: Multithreading(root: root, kind: .encoder, queue: encoderOutputQueue),
                                          checkbox: view.setupMultithreadingButton)
            let duplicatesMetal = Checkbox(next: DuplicatesApproxMetal(root: root),
                                           checkbox: view.setupSenderDuplicatesMetalButton)
            let duplicatesMemcmp = Checkbox(next: DuplicatesStrictMemcmp(root: root),
                                            checkbox: view.setupSenderDuplicatesMemcmpButton)
            let duplicates = Checkbox(next: broadcast([duplicatesMetal, duplicatesMemcmp]) ?? Video.Setup.shared,
                                      checkbox: view.setupSenderDuplicatesButton)
            let recolor = Recolor()
            let webSocketHelm = Checkbox(
                next: cast(video: Network.Setup.WebSocket(helm: root, url: wsSenderHelm, target: .none)),
                checkbox: view.setupSenderWebSocketButton)
            let webSocketACKMetric = String.Processor.TableView(tableView: view.tableViewACK1)
            let webSocketACK = Checkbox(
                next: Checkbox(next: SenderACK(root: root, timebase: timebase, metric: webSocketACKMetric),
                               checkbox: view.setupSenderWebSocketACKButton),
                checkbox: view.setupSenderWebSocketButton)
            
            let webSocketQuality = Checkbox(
                next: Checkbox(next: SenderQuality(root: root),
                               checkbox: view.setupSenderWebSocketQualityButton),
                checkbox: view.setupSenderWebSocketButton)
            
            let captureFPS = MeasureFPSLabel(label: view.inputFPSLabel)
            let captureFPSsetup = Measure(kind: .capture, measure: captureFPS)
            
            let duplicatesFPS = MeasureFPSLabel(label: view.outputFPSLabel)
            let duplicatesFPSsetup = Measure(kind: .duplicatesFree, measure: duplicatesFPS)
            
            let byterateString = String.Processor.TableView(tableView: view.tableViewByterate)
            let byterateMeasure = MeasureByterate(string: byterateString)
            let byterate = DataProcessor(data: byterateMeasure, kind: .networkData)
            
            let timestamp1string = String.Processor.FlushLast(String.Processor.TableView(tableView: view.tableViewTiming))
            let timestamp1processor = Video.Processor.OutputPresentationTime(string: timestamp1string, timebase: timebase)
            let timestamp1 = Processor(kind: .capture, video: timestamp1processor)
            
            let numThreads2table = String.Processor.TableView(tableView: view.tableViewThreads)
            let numThreads2string = String.Processor.ChainConstant(prepend: "threads number: ", next: numThreads2table)
            let numThreads = Flushable.OperationsNumber(queue: encoderOutputQueue, next: numThreads2string)
            
            let flushPeriodically = Flushable.Periodically(next: Flushable.Vector([ byterateMeasure,
                                                                                    captureFPS,
                                                                                    duplicatesFPS,
                                                                                    timestamp1string,
                                                                                    numThreads ]))
            
            root.session(Session.DispatchSync(session: flushPeriodically, queue: DispatchQueue.main), kind: .other)
            
            return [
                preview,
                encoder,
                serializer,
                deserializer,
                multithreading,
                webSocketHelm,
                webSocketACK,
                webSocketQuality,
                recolor,
                duplicates,
                captureFPSsetup,
                duplicatesFPSsetup,
                byterate,
                timestamp1,
                capture,
                cast(video: displayInfo) ]
        }
    }
}
#endif


#if os(OSX)
public protocol VideoSetupScreenCaptureView {
    var inputFPSLabel: NSTextField! { get }
    var outputFPSLabel: NSTextField! { get }
    
    var setupSenderWebSocketButton: NSButton! { get }
    var setupSenderWebSocketACKButton: NSButton! { get }
    var setupSenderWebSocketQualityButton: NSButton! { get }
    
    var setupSenderDuplicatesButton: NSButton! { get }
    var setupSenderDuplicatesMetalButton: NSButton! { get }
    var setupSenderDuplicatesMemcmpButton: NSButton! { get }
    
    var setupPreviewButton: NSButton! { get }
    var setupMultithreadingButton: NSButton! { get }
    
    var tableViewTiming: NSTableView! { get }
    var tableViewThreads: NSTableView! { get }
    var tableViewACK1: NSTableView! { get }
    var tableViewByterate: NSTableView! { get }
}
#endif


#if os(OSX)
public extension Video.Setup.ScreenCapture {
    typealias View = VideoSetupScreenCaptureView
}
#endif


#if os(OSX)
public class ScreenCaptureViews : NSObject, Video.Setup.ScreenCapture.View, Video.Setup.Receiver.View {
    @IBOutlet public private(set) var serverPathTextField: NSTextField!
    @IBOutlet public private(set) var inputFPSLabel: NSTextField!
    @IBOutlet public private(set) var outputFPSLabel: NSTextField!
    
    @IBOutlet public private(set) var setupSenderWebSocketButton: NSButton!
    @IBOutlet public private(set) var setupSenderWebSocketACKButton: NSButton!
    @IBOutlet public private(set) var setupSenderWebSocketQualityButton: NSButton!
    
    @IBOutlet public private(set) var setupSenderDuplicatesButton: NSButton!
    @IBOutlet public private(set) var setupSenderDuplicatesMetalButton: NSButton!
    @IBOutlet public private(set) var setupSenderDuplicatesMemcmpButton: NSButton!
    
    @IBOutlet public private(set) var setupEventsButton: NSButton!
    @IBOutlet public private(set) var setupDisplayButton: NSButton!
    @IBOutlet public private(set) var setupPreviewButton: NSButton!
    @IBOutlet public private(set) var setupMultithreadingButton: NSButton!
    
    @IBOutlet public private(set) var tableViewTiming: NSTableView!
    @IBOutlet public private(set) var tableViewThreads: NSTableView!
    @IBOutlet public private(set) var tableViewACK1: NSTableView!
    @IBOutlet public private(set) var tableViewByterate: NSTableView!
    
    @IBAction private func networkButtonsAction(_ sender: AnyObject) {}
    @IBAction private func duplicatesButtonsAction(_ sender: AnyObject) {}
    
    public func save() {
        Settings.screen.acknowledge = setupSenderWebSocketACKButton.state == .on
        Settings.screen.display     = setupDisplayButton.state == .on
        Settings.screen.duplicates  = setupSenderDuplicatesButton.state == .on
        Settings.screen.events      = setupEventsButton.state == .on
        Settings.screen.memcmp      = setupSenderDuplicatesMemcmpButton.state == .on
        Settings.screen.metal       = setupSenderDuplicatesMetalButton.state == .on
        Settings.screen.multithread = setupMultithreadingButton.state == .on
        Settings.screen.networking  = setupSenderWebSocketButton.state == .on
        Settings.screen.preview     = setupPreviewButton.state == .on
        Settings.screen.server      = serverPathTextField.stringValue
        Settings.screen.stream      = setupSenderWebSocketQualityButton.state == .on
    }
    
    public func restore() {
        setupSenderWebSocketACKButton.state     = Settings.screen.acknowledge ? .on : .off
        setupDisplayButton.state                = Settings.screen.display ? .on : .off
        setupSenderDuplicatesButton.state       = Settings.screen.duplicates ? .on : .off
        setupEventsButton.state                 = Settings.screen.events ? .on : .off
        setupSenderDuplicatesMemcmpButton.state = Settings.screen.memcmp ? .on : .off
        setupSenderDuplicatesMetalButton.state  = Settings.screen.metal ? .on : .off
        setupMultithreadingButton.state         = Settings.screen.multithread ? .on : .off
        setupSenderWebSocketButton.state        = Settings.screen.networking ? .on : .off
        setupPreviewButton.state                = Settings.screen.preview ? .on : .off
        serverPathTextField.stringValue         = Settings.screen.server
        setupSenderWebSocketQualityButton.state = Settings.screen.stream ? .on : .off
    }
}


public extension Video {
    typealias ScreenCaptureViews = BlackMedia.ScreenCaptureViews
}
#endif
