//
//  Peer.Log.Container.swift
//  Camera
//
//  Created by Ivan Kh on 24.01.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import UIKit


class PeerLogTableController : BlackRx.TableController<Peer.Log.Item, Peer.Log.TableCell> {}
class PeerLogTableCell: BlackRx.TableCell<Peer.Log.Item> {}


extension Peer.Log {
    typealias TableCell = PeerLogTableCell
    typealias TableController = PeerLogTableController
}
