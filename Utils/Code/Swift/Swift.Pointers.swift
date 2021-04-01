//
//  Swift.Pointers.swift
//  Capture
//
//  Created by Ivan Kh on 11.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

public func bridge<T : AnyObject>(obj : T) -> UnsafeRawPointer {
return UnsafeRawPointer(Unmanaged.passUnretained(obj).toOpaque())
}

public func bridge<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
}

public func bridgeRetained<T : AnyObject>(obj : T) -> UnsafeRawPointer {
return UnsafeRawPointer(Unmanaged.passRetained(obj).toOpaque())}

public func bridgeRetained<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
return Unmanaged<T>.fromOpaque(ptr).takeRetainedValue()}
