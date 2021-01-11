//
//  Network.WebSocket.swift
//  Capture
//
//  Created by Ivan Kh on 03.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation
import Starscream

fileprivate extension String {
    static let wsSender =
    """
    ws://relay.raghava.io/proxy/connect?username=fL1VmUj0bK&machine_id=machine_mac&action=start_host_machine&token=vu8kd7ovvcJqp4uQeuD6OZQCUtWzX8BxeV7W1mq6fDdgsOkpVQeiTe73n6eleYvW6Nzom5fAWEJP5r6TBRUsx7tv6htvgIhdgEKqzKNfQ2G8d5CPUudhrvR6l4lc4TuuCHxdzZycSRCFQrraIUCYGujiArWe2ei7FuVZ1juerRSsrQ95ZUzlOIJJO7lGlNEupIxrHSgKt8F3e95802zsNcWsWh8Vgky985TXqq8gELVqK4VD692noib5bZU9GAy
    """

    static let wsReceiver =
    """
    ws://relay.raghava.io/proxy/connect?username=fL1VmUj0bK&machine_id=machine_mac&action=connect_to_host_machine&token=vu8kd7ovvcJqp4uQeuD6OZQCUtWzX8BxeV7W1mq6fDdgsOkpVQeiTe73n6eleYvW6Nzom5fAWEJP5r6TBRUsx7tv6htvgIhdgEKqzKNfQ2G8d5CPUudhrvR6l4lc4TuuCHxdzZycSRCFQrraIUCYGujiArWe2ei7FuVZ1juerRSsrQ95ZUzlOIJJO7lGlNEupIxrHSgKt8F3e95802zsNcWsWh8Vgky985TXqq8gELVqK4VD692noib5bZU9GAy
    """
}

public class WebSocketBase : SessionProtocol, DataProcessorProtocol, WebSocketDelegate {
    private let name: String
    private let next: DataProcessorProtocol?
    private let urlString: String
    private(set) var socket: WebSocket?
    private var connected: Func?

    init(name: String, urlString: String, next: DataProcessorProtocol?) {
        var urlStringVar = urlString
        var urlStringPath = Settings.shared.server
        
        if let path = UserDefaults(suiteName: "group.com.idrive.screentest")?.string(forKey: "server_path") {
            urlStringPath = path
        }

        urlStringVar = urlStringVar.replacingOccurrences(of: "machine_mac", with: name)
        urlStringVar = urlStringVar.replacingOccurrences(of: "ws://relay.raghava.io/proxy", with: urlStringPath)

        self.name = name
        self.urlString = urlStringVar
        self.next = next
    }
    
    func start() throws {
        var request = URLRequest(url: URL(string: urlString)!)
        request.timeoutInterval = 5
       
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
        
        wait { (done) in
            self.connected = done
        }

        print("connected2 \(name)")
    }
    
    func stop() {
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


public class WebSocketMaster : WebSocketBase {
    init(name: String, next: DataProcessorProtocol? = nil) {
        super.init(name: name, urlString: .wsSender, next: next)
    }
}


class WebSocketSlave : WebSocketBase {
    init(name: String, next: DataProcessorProtocol? = nil) {
        super.init(name: name, urlString: .wsReceiver, next: next)
    }
}


extension WebSocketBase {
    class SetupBase : CaptureSetup.Slave {
        typealias Create = (_ name: String, _ next: DataProcessor.Proto) -> WebSocketBase
        private var webSocket: DataProcessor.Proto?
        private let name: String
        private let session: Session.Kind
        private let target: DataProcessor.Kind
        private let network: DataProcessor.Kind
        private let output: DataProcessor.Kind
        private let create: Create

        init(root: CaptureSetup.Proto,
             name: String,
             session: Session.Kind,
             target: DataProcessor.Kind,
             network: DataProcessor.Kind,
             output: DataProcessor.Kind,
             create: @escaping Create) {
            self.name = name
            self.session = session
            self.network = network
            self.output = output
            self.create = create
            self.target = target
            super.init(root: root)
        }
        
        init(data root: CaptureSetup.Proto, target: DataProcessor.Kind, create: @escaping Create) {
            self.name = "machine_mac_data"
            self.session = .networkData
            self.network = .networkData
            self.output = .networkDataOutput
            self.create = create
            self.target = target
            super.init(root: root)
        }
        
        init(helm root: CaptureSetup.Proto, target: DataProcessor.Kind, create: @escaping Create) {
            self.name = "machine_mac_helm"
            self.session = .networkHelm
            self.network = .networkHelm
            self.output = .networkHelmOutput
            self.target = target
            self.create = create
            super.init(root: root)
        }

        override func session(_ session: Session.Proto, kind: Session.Kind) {
            if kind == .initial {
                let webSocketData: DataProcessorProtocol = root.data(DataProcessor.shared, kind: self.output)
                let webSocket = create(name, webSocketData)
                
                root.session(webSocket, kind: self.session)
                self.webSocket = root.data(webSocket, kind: self.network)
            }
        }
        
        override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
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


extension WebSocketMaster {
    class SetupData : SetupBase {
        init(root: CaptureSetup.Proto, target: DataProcessor.Kind) {
            super.init(data: root, target: target, create: { return WebSocketMaster(name: $0, next: $1) })
        }
    }

    
    class SetupHelm : SetupBase {
        init(root: CaptureSetup.Proto, target: DataProcessor.Kind) {
            super.init(helm: root, target: target, create: { return WebSocketMaster(name: $0, next: $1) })
        }
    }
}

extension WebSocketSlave {
    class SetupData : SetupBase {
        init(root: CaptureSetup.Proto, target: DataProcessor.Kind) {
            super.init(data: root, target: target, create: { return WebSocketSlave(name: $0, next: $1) })
        }
    }

    
    class SetupHelm : SetupBase {
        init(root: CaptureSetup.Proto, target: DataProcessor.Kind) {
            super.init(helm: root, target: target, create: { return WebSocketSlave(name: $0, next: $1) })
        }
    }
}
