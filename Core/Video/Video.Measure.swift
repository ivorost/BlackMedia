//
//  Video.FPS.swift
//  Capture
//
//  Created by Ivan Kh on 01.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation
import AppKit

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


class MeasureFPSLabel : MeasureFPS {
    let label: NSTextField

    init(label: NSTextField) {
        self.label = label
        super.init { _ in }
    }
    
    override func process(cps: Double) {
        dispatchMainAsync {
            self.label.stringValue = "\(Int(cps))"
        }
        super.process(cps: cps)
    }
}


class MeasureVideo : VideoOutputProtocol {
    private let measure: MeasureProtocol
    private let next: VideoOutputProtocol
    
    init(measure: MeasureProtocol, next: VideoOutputProtocol) {
        self.measure = measure
        self.next = next
    }
    
    func process(video: CMSampleBuffer) {
        measure.begin()
        next.process(video: video)
        measure.end()
    }
}


class VideoSetupMeasure : VideoSetup {
    let kind: VideoOutputKind
    let measure: MeasureProtocol
    
    init(kind: VideoOutputKind, measure: MeasureProtocol) {
        self.kind = kind
        self.measure = measure
    }
    
    override func video(_ video: VideoOutputProtocol, kind: VideoOutputKind) -> VideoOutputProtocol {
        var result = video
        
        if kind == self.kind {
            result = VideoOutputImpl(prev: result, measure: measure)
        }
        
        return result
    }
}
