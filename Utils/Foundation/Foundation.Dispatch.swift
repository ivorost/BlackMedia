//
//  Foundation.Dispatch.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 12.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import Foundation

public func dispatchMainSync(_ f: Func) {
    if Thread.isMainThread {
        autoreleasepool {
            f()
        }
    }
    else {
        DispatchQueue.main.sync {
            autoreleasepool {
                f()
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
