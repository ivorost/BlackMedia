//
//  Listen.ViewController.swift
//  CaptureIOS Upload Extension
//
//  Created by Ivan Kh on 21.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import UIKit

class ListenViewController : UIViewController {
    @IBOutlet weak var sampleBufferView: SampleBufferDisplayView!
    var session: Session.Proto?
    
    override func viewWillDisappear(_ animated: Bool) {
        session?.stop()
    }
}
