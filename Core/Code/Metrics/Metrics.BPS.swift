//
//  Video.FPS.swift
//  Capture
//
//  Created by Ivan Kh on 27.10.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation


public class MeasureByterate : MeasureCPS, Data.Processor.Proto {
    private let string: String.Processor.AnyProto
    
    public init(string: String.Processor.AnyProto) {
        self.string = string
        super.init()
    }
    
    public func process(_ data: Data) {
        measure(count: data.count)
    }
    
    override func process(cps: Double) {
//        let cpsString = ByteCountFormatter.string(fromByteCount: Int64(cps), countStyle: .binary)
        let cpsString = "\(Int(cps * 8.0 / 1024.0))".padding(toLength: 5, withPad: " ", startingAt: 0)
        string.process("\(cpsString) Kbits/s")
    }
}
