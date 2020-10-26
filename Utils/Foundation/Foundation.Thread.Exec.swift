//
//  Utils.Thread.Exec.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 15.07.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import Foundation

fileprivate func exec<T>(name: T, sync: Bool, block: @escaping Func) {
    let thread = BackgroundThread(name)
    
    thread.start()
    thread.exec(sync: sync) {
        block()
        thread.cancel()
    }
}

public func execSync<T>(name: T, _ block: @escaping Func) {
    exec(name: name, sync: true, block: block)
}

public func execAsync<T>(name: T, _ block: @escaping Func) {
    exec(name: name, sync: false, block: block)
}
