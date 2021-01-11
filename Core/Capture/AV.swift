//
//  Video.Utils.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 30.04.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation

class Capture {
    enum Error : Swift.Error {
        case audio(_ inner: Swift.Error)
        case video(_ inner: Swift.Error)
    }

    static let shared = Capture()
    let captureQueue = DispatchQueue.CreateCheckable("capture_queue")
    let outputQueue = DispatchQueue.CreateCheckable("output_queue")
    let setupQueue = DispatchQueue.CreateCheckable("setup_queue")
}
