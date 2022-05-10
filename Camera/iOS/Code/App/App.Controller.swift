//
//  ViewController.swift
//  CaptureIOS
//
//  Created by Ivan Kh on 17.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import UIKit
import ReplayKit
import RxSwift


class AppController: UIViewController {
    private(set) var peersDiscovery: Peer.Bonjour.Session?
    let peersSubject: BehaviorSubject<[Peer.Proto]>
    let peersLog = Peer.Log.BehaviorSubject()
    let peerSelector: Peer.Selector
    let put: Peer.Put
    private let bag = DisposeBag()
    
    required init?(coder: NSCoder) {
        peersSubject = BehaviorSubject<[Peer.Proto]>(value: [])
        peerSelector = Peer.Selector(peers: peersSubject)
        put = Peer.Put(peerSelector)
        super.init(coder: coder)
    }
}


extension AppController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peersDiscovery = Peer.Bonjour.Session(log: peersLog)
        peersDiscovery?.rx.peers.subscribe(peersSubject).disposed(by: bag)
        try? peersDiscovery?.start()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        _ = segue.destination.view
    }
}


extension AppController {
    @IBAction private func babyButtonAction(_ sender: Any) {
        
    }

    @IBAction private func parentsButtonAction(_ sender: Any) {
        
    }
}
