//
//  Media.BaseController.swift
//  Camera
//
//  Created by Ivan Kh on 22.04.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import Foundation


import UIKit

class MediaBaseController : UIViewController {
    @IBOutlet weak var sampleBufferView: SampleBufferDisplayView!
    var session: Session.Proto?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sampleBufferView.sampleLayer.videoGravity = .resizeAspect
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Core.Capture.queue.async {
            self.session?.stop()
        }
    }
}
