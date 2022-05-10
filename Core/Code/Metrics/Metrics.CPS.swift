//
//  Video.FPS.swift
//  Capture
//
//  Created by Ivan Kh on 27.10.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation
#if os(OSX)
import Cocoa
#endif

fileprivate extension TimeInterval {
    static let calcDuration: TimeInterval = 3 // in seconds
}


public class MeasureCPS : Flushable {
    private var data = [(count: Int, timestamp: Date)]()
    private var callback: FuncWithDouble?
    private let lock = NSLock()
    private let next: String.Processor.Proto
    
    init(next: String.Processor.Proto = String.Processor.Print.shared) {
        self.next = next
    }
    
    func measure(count: Int) {
        lock.locked {
            data.append((count: count, timestamp: Date()))
        }
    }
    
    public override func flush() {
        lock.locked {
            let date = Date()
            flushData(date)
            let cps = calcCPS(date)
            process(cps: cps)
        }
    }
    
    func process(cps: Double) {
        next.process(string: "\(cps)")
    }
    
    private func flushData(_ date: Date) {
        data.removeAll { date.timeIntervalSince($0.timestamp) > .calcDuration }
    }
    
    private func calcCPS(_ date: Date) -> Double {
        guard let first = data.first else { return 0 }
        return data.map{ Double($0.count) }.reduce(0, +) / max(1, date.timeIntervalSince(first.timestamp))
    }
}


public class MeasureFPS : MeasureCPS, MeasureProtocol {
    public func begin() {
    }
    
    public func end() {
        measure(count: 1)
    }
}


#if os(OSX)
public class MeasureFPSLabel : MeasureFPS {
    let label: NSTextField

    public init(label: NSTextField) {
        self.label = label
    }
    
    override func process(cps: Double) {
        dispatchMainAsync {
            self.label.stringValue = "\(Int(cps))"
        }
        super.process(cps: cps)
    }
}
#endif
