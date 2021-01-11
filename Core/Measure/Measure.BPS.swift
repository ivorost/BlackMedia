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
    let next: DataProcessor?
    
    init(next: DataProcessor?, callback: @escaping FuncWithDouble) {
        self.next = next
        super.init(callback: callback)
    }
    
    func process(data: Data) {
        measure(count: data.count)
        next?.process(data: data)
    }
}


class MeasureByteratePrint : MeasureByterate {
    let title: String
    
    init(title: String, next: DataProcessor?, callback: @escaping FuncWithDouble) {
        self.title = title
        super.init(next: next, callback: callback)
    }
    
    override func process(cps: Double) {
        super.process(cps: cps)
        print("\(title) \(cps)")
    }
}
