//
//  Peer.Model.swift
//  Camera
//
//  Created by Ivan Kh on 08.12.2021.
//  Copyright © 2021 Ivan Kh. All rights reserved.
//

import Foundation
import Bonjour
import RxSwift
import CoreMedia


final class Peer {}


protocol PeerProtocol : AnyObject {
    var id: String { get }
    var name: String { get }
    var state: Peer.State { get }
    var rx: Peer.Rx { get }
    
    func send(_ data: Data)
    func receive(_ data: Data)
}


extension Peer {
    class Base : PeerProtocol {
        let id: String
        var name = "" { didSet { rxName.onNext(name) } }
        var state: State = .unavailable { didSet {
            rxState.onNext(state)
        } }
        let rx: Rx
        
        private let rxName: PublishSubject<String>
        private let rxState: PublishSubject<State>
        private let rxSend: PublishSubject<Data>
        private let rxReceive: PublishSubject<Data>
        
        init(id: String) {
            let rxName = PublishSubject<String>()
            let rxState = PublishSubject<State>()
            let rxSend = PublishSubject<Data>()
            let rxReceive = PublishSubject<Data>()

            self.id = id
            self.rxName = rxName
            self.rxState = rxState
            self.rxSend = rxSend
            self.rxReceive = rxReceive
            self.rx = Rx(name: rxName, state: rxState, send: rxSend, receive: rxReceive)
        }
        
        func send(_ data: Data) {
            rxSend.onNext(data)
        }
        
        func receive(_ data: Data) {
            rxReceive.onNext(data)
        }
    }
}


extension Peer {
    typealias Proto = PeerProtocol
}


extension Peer {
    enum State {
        case unavailable
        case available
        case disconnected
        case connected
        case connecting
    }
}


extension Peer {
    struct Rx {
        let name: Observable<String>
        let state: Observable<State>
        let send: Observable<Data>
        let receive: Observable<Data>
    }
}


extension Array where Element : Peer.Proto {
    func first(id: String) -> Element? {
        return first { $0.id == id }
    }
    
    @discardableResult mutating func removeFirst(_ peer: Element) -> Element? {
        return removeFirst { $0.id == peer.id }
    }
}
