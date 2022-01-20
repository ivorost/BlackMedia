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
    let peersSubject = BehaviorSubject<[Peer.Proto]>(value: [])
    let peersLog = Peer.Log.BehaviorSubject()
    private let bag = DisposeBag()
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
