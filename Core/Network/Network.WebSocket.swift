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

class WebSocketSession : SessionProtocol, DataProcessor, WebSocketDelegate {
    private let next: DataProcessor?
    private let urlString: String
    private(set) var socket: WebSocket?

    init(urlString: String, next: DataProcessor?) {
        self.urlString = urlString
        self.next = next
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
    
    func process(data: Data) {
        socket?.write(data: data)
    }

    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .binary(let data):
            next?.process(data: data)
        default:
            break
        }
    }
}


class WebSocketOutput : WebSocketSession {
    init(input: DataProcessor? = nil) {
        super.init(urlString: .wsSender, next: input)
    }
}


class WebSocketInput : WebSocketSession {
    init(_ next: DataProcessor? = nil) {
        super.init(urlString: .wsReceiver, next: next)
    }
}
