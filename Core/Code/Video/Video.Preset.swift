//
//  Video.Preset.swift
//  Core
//
//  Created by Ivan Kh on 08.04.2022.
//

#if os(OSX)
import Cocoa
#endif

#if os(OSX)
public extension Video.Setup {
    class Receiver : Vector {
        private let view: View
        private let layer: SampleBufferDisplayLayer
        private let root: Proto
        
        public init(root: Proto, view: View, layer: SampleBufferDisplayLayer) {
            self.root = root
            self.view = view
            self.layer = layer
            super.init()
        }
        
        public override func create() -> [Proto] {
            guard let wsReceiverHelm = URL.wsReceiverHelm else { assert(false); return [] }
            
            let window = (layer.delegate as? NSView)?.window
            let preview = Display(root: root, layer: layer, kind: .deserializer)//.decoder)
            let orientation = LayerOrientation(layer: layer)
            let deserializer = DeserializerH264(root: root, kind: .networkDataOutput)
            var autosizeWindow: Data.Setup.Proto = Data.Setup.shared
            if let window = window { autosizeWindow = Data.Setup.AutosizeWindow(root: root, window: window) }
            let webSocketHelm = Checkbox(
                next: cast(video: Network.Setup.WebSocket(helm: root, url: wsReceiverHelm, target: .serializer)),
                checkbox: view.setupSenderWebSocketButton)
            let webSocketACK = Checkbox(next: ViewerACK(root: root), checkbox: view.setupSenderWebSocketACKButton)
            let webSocketQuality = Checkbox(next: ViewerQuality(root: root), checkbox: view.setupSenderWebSocketQualityButton)
            let fps = MeasureFPSLabel(label: view.inputFPSLabel)
            let fpsSetup = Measure(kind: .deserializer, measure: fps)
            
            let byterateString = String.Processor.TableView(tableView: view.tableViewByterate)
            let byterateMeasure = MeasureByterate(string: byterateString)
            let byterate = DataProcessor(data: byterateMeasure, kind: .networkDataOutput)
            
            let timestamp1string = String.Processor.FlushLast(String.Processor.TableView(tableView: view.tableViewTiming))
            let timestamp1processor = Video.Processor.PresentationDelay(next: timestamp1string)
            let timestamp1video = Processor(kind: .preview, video: timestamp1processor)
            let timestamp1data = Data.Setup.Default(prev: timestamp1processor, kind: .networkDataOutput)
            
            let flushPeriodically = Flushable.Periodically(next: Flushable.Vector([ byterateMeasure,
                                                                                    fps,
                                                                                    timestamp1string ]))
            
            root.session(Session.DispatchSync(session: flushPeriodically, queue: DispatchQueue.main), kind: .other)
            
            return [
                preview,
                orientation,
                deserializer,
                webSocketHelm,
                webSocketACK,
                webSocketQuality,
                byterate,
                timestamp1video,
                cast(video: autosizeWindow),
                cast(video: timestamp1data),
                fpsSetup ]
        }
    }
}
#endif


#if os(OSX)
public protocol VideoSetupReceiverView {
    var setupSenderWebSocketButton: NSButton! { get }
    var setupSenderWebSocketACKButton: NSButton! { get }
    var setupSenderWebSocketQualityButton: NSButton! { get }
    var inputFPSLabel: NSTextField! { get }
    var tableViewTiming: NSTableView! { get }
    var tableViewByterate: NSTableView! { get }
}
#endif


#if os(OSX)
public extension Video.Setup.Receiver {
    typealias View = VideoSetupReceiverView
}
#endif


#if os(iOS)
public extension Video.Setup {
    static func get(layer: SampleBufferDisplayLayer) -> Video.Setup.Vector {
        //            guard
        //                let wsReceiverData = URL.wsReceiverData,
        //                let wsReceiverHelm = URL.wsReceiverHelm
        //            else { assert(false); return [] }
        
        let root = Vector()
        
        root.append(cast(video: Session.Setup.Aggregator()))
        root.append(Display(root: root, layer: layer, kind: .deserializer))
        root.append(LayerOrientation(layer: layer))
        root.append(DeserializerH264(root: root, kind: .networkDataOutput))
//        root.append(Network.WebSocketClient.Setup(helm: root, url: wsReceiverHelm, target: .serializer))
//        root.append(ViewerACK(root: root))
        
        return root
    }
    
    static func get(websocket url: URL, layer: SampleBufferDisplayLayer) -> Video.Setup.Vector {
        let root = get(layer: layer)
        let network = Network.Setup.WebSocket(data: root, url: url, target: .deserializer)
        
        root.prepend(cast(video: network))
        return root
    }
}
#endif
