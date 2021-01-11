//
//  Swift.Pointers.swift
//  Capture
//
//  Created by Ivan Kh on 11.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

func bridge<T : AnyObject>(obj : T) -> UnsafeRawPointer {
return UnsafeRawPointer(Unmanaged.passUnretained(obj).toOpaque())
}

func bridge<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
}

func bridgeRetained<T : AnyObject>(obj : T) -> UnsafeRawPointer {
return UnsafeRawPointer(Unmanaged.passRetained(obj).toOpaque())}

func bridgeRetained<T : AnyObject>(ptr : UnsafeRawPointer) -> T {
return Unmanaged<T>.fromOpaque(ptr).takeRetainedValue()}
