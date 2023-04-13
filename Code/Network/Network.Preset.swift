//
//  Network.Preset.swift
//  Core
//
//  Created by Ivan Kh on 08.04.2022.
//

#if os(OSX)
import AVFoundation
import Cocoa
#endif
import BlackUtils

#if os(OSX)
public extension Network.Setup {
    class Test : Capture.Setup.Vector {
        private weak var views: Network.TestView?
        private let url: URL

        public init(url: URL, views: Network.TestView) {
            self.url = url
            self.views = views
            super.init()
        }
        
        public override func create() -> [Capture.Setup.Proto] {
            guard
                let views = views,
                let kbits = UInt(views.kbitsTextField.stringValue),
                let interval = TimeInterval(views.intervalTextField.stringValue)
            else { return [] }

            let aggregator = Session.Setup.Aggregator()
            let aggregatorDispatch = Session.Setup.DispatchSync(next: aggregator, queue: Capture.Setup.queue)
            let websocket = Network.Setup.WebSocket(data: self, url: url, target: .capture)
            let test = Data.Setup.Test(root: self, kbits: kbits, interval: interval)

            let byterateString = String.Processor.TableView(tableView: views.capture.tableViewByterate)
            let byterateMeasure = MeasureByterate(string: byterateString)
            let byterate = Video.Setup.DataProcessor(data: byterateMeasure, kind: .networkData)

            let flushPeriodically = Flushable.Periodically(next: Flushable.Vector([ byterateMeasure ]))
            aggregator.session(Session.DispatchSync(session: flushPeriodically, queue: DispatchQueue.main), kind: .other)

            return [
                cast(capture: aggregatorDispatch),
                websocket,
                test,
                byterate
            ]
        }
    }
}
#endif


#if os(OSX)
public class NetworkTestView : NSObject {
    @IBOutlet private(set) var kbitsTextField: NSTextField!
    @IBOutlet private(set) var intervalTextField: NSTextField!
    @IBOutlet private(set) var testButton: NSButton!
    @IBOutlet private(set) var stopButton: NSButton!
    @IBOutlet private(set) var capture: Video.ScreenCaptureViews!
    private var session: Session.Proto?

    @IBAction func startAction(_ sender: Any) {
        guard let url = URL(string: "") else { return }
        let oldSession = self.session
        let newSession = Network.Setup.Test(url: url, views: self).setup()
        
        self.session = newSession

        Capture.queue.async {
            do {
                oldSession?.stop()
                try newSession?.start()
                
                dispatchMainSync {
                    self.testButton.isHidden = true
                    self.stopButton.isHidden = false
                }
            }
            catch {
                logError(error)
            }
        }
    }

    @IBAction func stopAction(_ sender: Any) {
        let session = self.session
        
        testButton.isHidden = false
        stopButton.isHidden = true
        self.session = nil

        Capture.queue.async {
            session?.stop()
        }
    }
}

public extension Network {
    typealias TestView = NetworkTestView
}
#endif
