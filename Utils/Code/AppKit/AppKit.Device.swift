//
//  AppKit.Device.swift
//  Utils
//
//  Created by Ivan Kh on 05.04.2023.
//

#if canImport(UIKit)
import UIKit
#endif

public extension Device {
    #if canImport(UIKit)
    static var name: String {
        UIDevice.current.name
    }
    #endif
}
