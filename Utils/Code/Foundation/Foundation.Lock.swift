//
//  Foundation.Lock.swift
//  Capture
//
//  Created by Ivan Kh on 12.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

public extension NSLocking {
    func locked<T>(_ block: () -> T) -> T {
        lock()
        let result = block()
        unlock()
        return result
    }
}
