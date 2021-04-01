//
//  General.Status.swift
//  Utils
//
//  Created by Ivan Kh on 08.02.2021.
//

import Foundation


public extension OSStatus {
    enum Error : Swift.Error {
        case status(code: OSStatus, message: String)
    }
}


public func check(status: OSStatus, message: String) throws {
    guard status == 0 else {
        throw OSStatus.Error.status(code: status, message: message)
    }
}
