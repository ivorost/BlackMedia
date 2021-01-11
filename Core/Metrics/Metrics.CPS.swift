//
//  Video.FPS.swift
//  Capture
//
//  Created by Ivan Kh on 27.10.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

fileprivate extension TimeInterval {
    static let calcDuration: TimeInterval = 3 // in seconds
}

class MeasureCPS : Flushable {
    private var data = [(count: Int, timestamp: Date)]()
    private var callback: FuncWithDouble?
    private let lock = NSLock()
    
    func measure(count: Int) {
        lock.locked {
            data.append((count: count, timestamp: Date()))
        }
    }
    
    override func flush() {
        lock.locked {
            let date = Date()
            flushData(date)
            let cps = calcCPS(date)
            process(cps: cps)
        }
    }
    
    func process(cps: Double) {
    }
    
    private func flushData(_ date: Date) {
        data.removeAll { date.timeIntervalSince($0.timestamp) > .calcDuration }
    }
    
    private func calcCPS(_ date: Date) -> Double {
        guard let first = data.first else { return 0 }
        return data.map{ Double($0.count) }.reduce(0, +) / max(1, date.timeIntervalSince(first.timestamp))
    }
}
