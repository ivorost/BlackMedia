//
//  Utils.Thread.Wait.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 14.07.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import Foundation

fileprivate extension Double {
    static let runLoopInterval = 0.1
}

public func wait(_ asyncBlock: (@escaping Func) -> Void) {
    wait(interval: .runLoopInterval, timeout: nil, asyncBlock)
}

public func wait(_ asyncBlock: (@escaping Func) throws -> Void) throws {
    try wait(interval: .runLoopInterval, timeout: nil, throwingAsyncBlock: asyncBlock)
}

public func wait(interval: Double, timeout: Double? = nil, throwingAsyncBlock: (@escaping Func) throws -> Void) throws {
    let date = Date()
    var done = false
    let doneBlock: () -> Void = {
        done = true
    }
    
    try throwingAsyncBlock(doneBlock)

    #if DEBUG
    var i = 0
    #endif
    
    while true {
        #if DEBUG
        i += 1
        if i > 5000 { assert(false) }
        #endif
        
        if done {
            break
        }
        
        if let timeout = timeout, Date().timeIntervalSince(date) > timeout {
            break
        }
        
        RunLoop.current.run(mode: .default,
                            before: Date().addingTimeInterval(interval))
    }
}

public func wait(interval: Double, timeout: Double? = nil, _ asyncBlock: (@escaping Func) -> Void) {
    try? wait(interval: interval, timeout: timeout, throwingAsyncBlock: asyncBlock)
}
