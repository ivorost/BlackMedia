//
//  Measure.Duration.swift
//  Capture
//
//  Created by Ivan Kh on 01.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation


class MeasureDuration : MeasureProtocol {
    private var startDate = Date()
    private(set) var milliseconds: TimeInterval = 0
    
    func begin() {
        startDate = Date()
    }
    
    func end() {
        milliseconds = Date().timeIntervalSince(startDate) * 1000
        process(milliseconds: milliseconds)
    }
    
    func process(milliseconds: TimeInterval) {
        
    }
}


class MeasureDurationPrint : MeasureDuration {
    let title: String
    
    init(title: String) {
        self.title = title
    }
    
    override func process(milliseconds: TimeInterval) {
        print("\(title) \(milliseconds)")
        super.process(milliseconds: milliseconds)
    }
}


class MeasureDurationAverage : MeasureProtocol {
    private let duration = MeasureDuration()
    private var count = 0
    private var sum: TimeInterval = 0
    
    func begin() {
        duration.begin()
    }
    
    func end() {
        duration.end()
        
        count += 1
        sum += duration.milliseconds
        process(milliseconds: sum / Double(count))
    }
    
    func process(milliseconds: TimeInterval) {
        
    }
}


class MeasureDurationAveragePrint : MeasureDurationAverage {
    let title: String
    
    init(title: String) {
        self.title = title
    }
    
    override func process(milliseconds: TimeInterval) {
        print("\(title) \(milliseconds)")
        super.process(milliseconds: milliseconds)
    }
}

