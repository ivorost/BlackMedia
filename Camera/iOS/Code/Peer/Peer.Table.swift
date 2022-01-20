//
//  Peer.TableView.swift
//  Camera
//
//  Created by Ivan Kh on 07.12.2021.
//  Copyright © 2021 Ivan Kh. All rights reserved.
//

import UIKit
import Foundation
import Utils
import RxSwift
import RxCocoa



class PeerTableController : BlackRx.TableController<Peer.Proto, Peer.TableCell> {}



class PeerTableCell : BlackRx.TableCell<Peer.Proto> {
    override func bind(to peer: Peer.Proto) {
        let nameBehaviorSubject = BehaviorSubject<String>(value: peer.name)
        let stateBehaviorSubject = BehaviorSubject<Peer.State>(value: peer.state)
        
        peer.rx.name.bind(to: nameBehaviorSubject).disposed(by: disposeBag)
        peer.rx.state.bind(to: stateBehaviorSubject).disposed(by: disposeBag)
        
        let titleLabelValue = Observable.combineLatest(nameBehaviorSubject, stateBehaviorSubject) { name, state in
            return "\(name) \(state)"
        }
        
        titleLabelValue.bind(to: titleLabel.rx.text).disposed(by: disposeBag)
    }
}


extension Peer {
    typealias TableCell = PeerTableCell
    typealias TableController = PeerTableController

}
