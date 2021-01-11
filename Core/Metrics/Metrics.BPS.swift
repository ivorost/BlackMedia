//
//  Video.FPS.swift
//  Capture
//
//  Created by Ivan Kh on 27.10.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation
import AppKit


class MeasureByterate : MeasureCPS, DataProcessor {
    let string: StringProcessorProtocol?
    
    init(string: StringProcessorProtocol?) {
        self.string = string
        super.init(callback: { _ in })
    }
    
    func process(data: Data) {
        measure(count: data.count)
    }
    
    override func process(cps: Double) {
        let cpsString = ByteCountFormatter.string(fromByteCount: Int64(cps),
                                                  countStyle: .binary)
        string?.process(string: cpsString)
    }
}
