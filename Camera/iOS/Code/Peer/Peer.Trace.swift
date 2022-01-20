//
//  Peer.swift
//  Camera
//
//  Created by Ivan Kh on 08.12.2021.
//  Copyright © 2021 Ivan Kh. All rights reserved.
//

import UIKit


class PeerTraceController : UIViewController {
    private(set) var peers: Peer.TableController?
    private(set) var logs: Peer.Log.TableController?
}


extension PeerTraceController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let controller = segue.destination as? Peer.TableController {
            self.peers = controller
        }

        if let controller = segue.destination as? Peer.Log.TableController {
            self.logs = controller
        }
    }
}
