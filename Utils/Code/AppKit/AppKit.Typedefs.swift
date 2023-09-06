//
//  AppKit.Typedefs.swift
//  Utils
//
//  Created by Ivan Kh on 24.01.2022.
//

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
import Cocoa
#endif


#if canImport(UIKit)
public typealias AppleScreen = UIScreen
public typealias AppleView = UIView
public typealias AppleViewController = UIViewController
public typealias AppleColor = UIColor
public typealias AppleImage = UIImage
public typealias AppleApplicationDelegate = UIResponder
public typealias AppleStoryboard = UIStoryboard
public typealias AppleStoryboardSegue = UIStoryboardSegue
#endif

#if canImport(AppKit)
public typealias AppleScreen = NSScreen
public typealias AppleView = NSView
public typealias AppleViewController = NSViewController
public typealias AppleColor = NSColor
public typealias AppleImage = NSImage
public typealias AppleApplicationDelegate = NSObject
public typealias AppleStoryboard = NSStoryboard
public typealias AppleStoryboardSegue = NSStoryboardSegue
#endif
