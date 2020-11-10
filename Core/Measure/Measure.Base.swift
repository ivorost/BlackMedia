//
//  Measure.Base.swift
//  Capture
//
//  Created by Ivan Kh on 01.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

protocol MeasureProtocol {
    func begin()
    func end()
}

class MeasureBegin : MeasureProtocol {
    let next: MeasureProtocol
    
    init(_ next: MeasureProtocol) {
        self.next = next
    }
    
    func begin() {
        next.begin()
    }
    
    func end() {
    }
}

class MeasureEnd : MeasureProtocol {
    let next: MeasureProtocol
    
    init(_ next: MeasureProtocol) {
        self.next = next
    }
    
    func begin() {
    }
    
    func end() {
        next.end()
    }
}
