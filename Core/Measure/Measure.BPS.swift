//
//  Video.FPS.swift
//  Capture
//
//  Created by Ivan Kh on 27.10.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation
import AppKit


fileprivate extension TimeInterval {
    static let blockDuration: TimeInterval = 1.5 // 1.5 second
}


fileprivate extension Int {
    static let maxBlockCount: Int = 4
}


class Byterate {
    private var history = [(bytes: Int, startDate: Date)]()
    private let log: Bool
    
    init(print: Bool) {
        self.log = print
    }
    
    func process(data: Data) {
        if let rate = calcRate() {
            process(rate: rate)
        }
        
        if history.count >= .maxBlockCount {
            history.removeFirst()
        }
        
        guard let lastData = history.last else {
            startNewBlock(data.count)
            return
        }

        if Date().timeIntervalSince(lastData.startDate) > .blockDuration {
            startNewBlock(data.count)
            return
        }

        history[history.count-1].bytes += data.count
    }
    
    open func process(rate: Int) {
        if self.log {
            print("data \(rate)")
        }
    }
    
    private func startNewBlock(_ bytes: Int) {
        history.append((bytes: bytes, startDate: Date()))
    }
    
    private func calcRate() -> Int? {
        guard let firstData = history.first else { return nil }
        
        let startDate = firstData.startDate
        let bytes = history.map{ $0.bytes }.reduce(0, +)
        
        return Int(Double(bytes) / Date().timeIntervalSince(startDate))
    }
}
