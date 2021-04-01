//
//  Network.WebSocket.swift
//  Capture
//
//  Created by Ivan Kh on 03.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation
import Starscream


public class WebSocketClient : SessionProtocol, DataProcessorProtocol, WebSocketDelegate {
    private let next: DataProcessorProtocol?
    private let url: URL
    private(set) var socket: WebSocket?
    private var connected: Func?

    init(url: URL, next: DataProcessorProtocol?) {
        self.url = url
        self.next = next
    }
    
    var name: String {
        return url.host ?? "unknown"
    }
    
    public func start() throws {
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
       
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
        
        wait { (done) in
            self.connected = done
        }

        print("connected2 \(name)")
    }
    
    public func stop() {
        socket?.disconnect()
    }
    
    public func process(data: Data) {
        socket?.write(data: data)
    }

    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .binary(let data):
            next?.process(data: data)
        case .connected(_):
            print("connected1 \(name)")
            connected?()
        default:
            break
        }
    }
}


public extension WebSocketClient.Setup {
    convenience init(data root: CaptureSetup.Proto, url: URL, target: DataProcessor.Kind) {
        self.init(root: root,
                  url: url,
                  session: .networkData,
                  target: target,
                  network: .networkData,
                  output: .networkDataOutput)
    }

    convenience init(helm root: CaptureSetup.Proto, url: URL, target: DataProcessor.Kind) {
        self.init(root: root,
                  url: url,
                  session: .networkHelm,
                  target: target,
                  network: .networkHelm,
                  output: .networkHelmOutput)
    }
}


public extension WebSocketClient {
    class Setup : CaptureSetup.Slave {
        private var webSocket: DataProcessor.Proto?
        private let url: URL
        private let session: Session.Kind
        private let target: DataProcessor.Kind
        private let network: DataProcessor.Kind
        private let output: DataProcessor.Kind

        public init(root: CaptureSetup.Proto,
                    url: URL,
                    session: Session.Kind,
                    target: DataProcessor.Kind,
                    network: DataProcessor.Kind,
                    output: DataProcessor.Kind) {
            self.url = url
            self.session = session
            self.network = network
            self.output = output
            self.target = target
            super.init(root: root)
        }
                
        public override func session(_ session: Session.Proto, kind: Session.Kind) {
            if kind == .initial {
                let webSocketData: DataProcessorProtocol = root.data(DataProcessor.shared, kind: self.output)
                let webSocket = WebSocketClient(url: url, next: webSocketData)
                
                root.session(webSocket, kind: self.session)
                self.webSocket = root.data(webSocket, kind: self.network)
            }
        }
        
        public override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
            var result = data
            
            if kind == target {
                if let webSocket = webSocket {
                    result = DataProcessor(prev: result, next: webSocket)
                }
                else {
                    assert(false)
                }
            }
            
            return super.data(result, kind: kind)
        }
    }
}
