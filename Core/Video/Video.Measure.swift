//
//  Video.FPS.swift
//  Capture
//
//  Created by Ivan Kh on 01.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation


typealias VideoFPS = VideoOutputImpl

extension VideoFPS {
    convenience init(_ measure: MeasureProtocol) {
        self.init(next: nil, measure: measure)
    }
}

class MeasureFPS : MeasureCPS, MeasureProtocol {
    func begin() {
    }
    
    func end() {
        measure(count: 1)
    }
}


class MeasureFPSPrint : MeasureFPS {
    
    let title: String
    
    init(title: String, callback: @escaping FuncWithDouble) {
        self.title = title
        super.init(callback: callback)
    }
    
    override func process(cps: Double) {
        print("\(title) \(cps)")
        super.process(cps: cps)
    }
}

