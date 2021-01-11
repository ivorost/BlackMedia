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

class WebSocketSession : SessionProtocol, WebSocketDelegate {
    private let urlString: String
    private(set) var socket: WebSocket?
    
    init(urlString: String) {
        self.urlString = urlString
    }
    
    func start() throws {
        var request = URLRequest(url: URL(string: urlString)!)
        request.timeoutInterval = 5
       
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
    
    func stop() {
        socket?.disconnect()
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .error(let error):
            print("websocket error \(String(describing: error))")
        default:
            break
        }
    }
}

class WebSocketOutput : WebSocketSession, DataProcessor {
    
    init() {
        super.init(urlString: .wsSender)
    }
    
    func process(data: NSData) {
        socket?.write(data: data as Data)
    }
    
}

class WebSocketInput : WebSocketSession {
    let next: DataProcessor?
    
    init(_ next: DataProcessor?) {
        self.next = next
        super.init(urlString: .wsReceiver)
    }
    
    override func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .binary(let data):
            next?.process(data: data as NSData)
        default:
            super.didReceive(event: event, client: client)
        }
    }
}
