//
//  Video.FPS.swift
//  Capture
//
//  Created by Ivan Kh on 27.10.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation


class MeasureByterate : MeasureCPS, DataProcessorProtocol {
    private let string: StringProcessor.Proto
    
    init(string: StringProcessor.Proto) {
        self.string = string
        super.init()
    }
    
    func process(data: Data) {
        measure(count: data.count)
    }
    
    override func process(cps: Double) {
//        let cpsString = ByteCountFormatter.string(fromByteCount: Int64(cps), countStyle: .binary)
        let cpsString = "\(Int(cps * 8.0 / 1024.0))".padding(toLength: 5, withPad: " ", startingAt: 0)
        string.process(string: "\(cpsString) Kbits/s")
    }
}
