//
//  Foundation.Dispatch.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 12.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import Foundation


public func dispatchMainSync<T>(_ f: () -> T) -> T {
    if Thread.isMainThread {
        return autoreleasepool {
            return f()
        }
    }
    else {
        return DispatchQueue.main.sync {
            return autoreleasepool {
                return f()
            }
        }
    }
}


public func dispatchMainAsync(_ f: @escaping Func) {
    DispatchQueue.main.async {
        autoreleasepool {
            f()
        }
    }
}


public func dispatchMainAfter(_ delay: Double, _ f: @escaping Func) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        autoreleasepool {
            f()
        }
    }
}


public extension DispatchQueue {
    func syncSafe(execute block: () -> Void) {
        if isCurrent {
            block()
        }
        else {
            sync { block() }
        }
    }
}
