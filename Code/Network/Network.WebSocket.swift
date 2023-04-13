//
//  Network.WebSocket.swift
//  Capture
//
//  Created by Ivan Kh on 03.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation
import Starscream
import BlackUtils


public extension Network {
    class WebSocketClient : Session.Proto, Data.Processor.Proto, CaptureProtocol, WebSocketDelegate {
        private let next: Data.Processor.AnyProto?
        private let url: URL
        private(set) var socket: WebSocket?
        private var connected: Func?
        
        init(url: URL, next: Data.Processor.AnyProto?) {
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
        
        public func process(_ data: Data) {
            socket?.write(data: data)
        }
        
        public func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {
            switch event {
            case .binary(let data):
                next?.process(data)
            case .connected(_):
                print("connected1 \(name)")
                connected?()
            default:
                break
            }
        }
    }
}


public extension Network.Setup.WebSocket {
    convenience init(data root: Capture.Setup.Proto, url: URL, target: Data.Processor.Kind) {
        self.init(root: root,
                  url: url,
                  session: .networkData,
                  target: target,
                  network: .networkData,
                  output: .networkDataOutput)
    }

    convenience init(helm root: Capture.Setup.Proto, url: URL, target: Data.Processor.Kind) {
        self.init(root: root,
                  url: url,
                  session: .networkHelm,
                  target: target,
                  network: .networkHelm,
                  output: .networkHelmOutput)
    }
}


public extension Network.Setup {
    class WebSocket : Get {
        private let url: URL
        
        public init(root: Capture.Setup.Proto,
                    url: URL,
                    session: Session.Kind,
                    target: Data.Processor.Kind,
                    network: Data.Processor.Kind,
                    output: Data.Processor.Kind) {
            self.url = url
            super.init(root: root, session: session, target: target, network: network, output: output)
        }

        public override func network(for next: Data.Processor.AnyProto, session: inout Session.Proto) -> Data.Processor.AnyProto {
            let result = Network.WebSocketClient(url: url, next: next)
            session = result
            return result
        }
    }
}
