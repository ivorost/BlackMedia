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
import Core


final class Peer {}


protocol PeerProtocol : Network.Peer.Proto, AnyObject {
    var rx: Peer.Rx { get }
}


extension Peer {
    typealias Proto = PeerProtocol
    typealias State = Network.Peer.State
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
        private let rxPut: PublishSubject<Data>
        private let rxGet: PublishSubject<Data>
        
        init(id: String) {
            let rxName = PublishSubject<String>()
            let rxState = PublishSubject<State>()
            let rxPut = PublishSubject<Data>()
            let rxGet = PublishSubject<Data>()

            self.id = id
            self.rxName = rxName
            self.rxState = rxState
            self.rxPut = rxPut
            self.rxGet = rxGet
            self.rx = Rx(name: rxName, state: rxState, put: rxPut, get: rxGet)
        }
        
        func connect() {
            state = .connecting
        }
        
        func disconnect() {
            state = .disconnecting
        }

        func put(_ data: Data) {
            rxPut.onNext(data)
        }
        
        func get(_ data: Data) {
            rxGet.onNext(data)
        }
    }
}


extension Peer {
    struct Rx {
        let name: Observable<String>
        let state: Observable<State>
        let put: Observable<Data>
        let get: Observable<Data>
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
