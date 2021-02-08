//
//  Video.Utils.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 30.04.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation

public class Capture {
    enum Error : Swift.Error {
        case audio(_ inner: Swift.Error)
        case video(_ inner: Swift.Error)
    }

    public static let shared = Capture()
    public let captureQueue = DispatchQueue.CreateCheckable("capture_queue")
    public let outputQueue = DispatchQueue.CreateCheckable("output_queue")
    public let setupQueue = DispatchQueue.CreateCheckable("setup_queue")
}
