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
    static let blockDuration: TimeInterval = 1 // 1.5 second
}


fileprivate extension Int {
    static let maxBlockCount: Int = 3
}


class MeasureCPS {
    private var data = [(count: Int, startDate: Date)]()
    private var callback: FuncWithDouble?
    private let lock = NSLock()
    
    init(callback: @escaping FuncWithDouble) {
        self.callback = callback
    }
    
    func measure(count: Int) {
        lock.locked {
            if let cps = calcCPS() {
                process(cps: cps)
            }
            
            if data.count >= .maxBlockCount {
                data.removeFirst()
            }
            
            guard let lastData = data.last else {
                startNewBlock(count: count)
                return
            }

            if Date().timeIntervalSince(lastData.startDate) > .blockDuration {
                startNewBlock(count: count)
                return
            }

            data[data.count-1].count += count
        }
    }
    
    open func process(cps: Double) {
        callback?(cps)
    }
    
    private func startNewBlock(count: Int) {
        data.append((count: count, startDate: Date()))
    }
    
    private func calcCPS() -> Double? {
        guard let firstData = data.first else { return nil }
        
        let startDate = firstData.startDate
        let count = data.map{ $0.count }.reduce(0, +)
        
        return Double(count) / Date().timeIntervalSince(startDate)
    }
}
