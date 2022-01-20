//
//  App.Controller.Segue.swift
//  Camera
//
//  Created by Ivan Kh on 08.12.2021.
//  Copyright © 2021 Ivan Kh. All rights reserved.
//

import UIKit
import Utils

class PeerTraceShowSegue : ConcreteSegue<AppController, PeerTraceController> {
    override func perform(source: AppController, destination: PeerTraceController) {
        super.perform(source: source, destination: destination)
        
        destination.peers?.items = source.peersSubject
        destination.logs?.items = source.peersLog.items
    }
}
