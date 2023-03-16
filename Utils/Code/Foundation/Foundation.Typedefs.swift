
import Foundation

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Typedefs
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if os(iOS)
import UIKit
public typealias AppleView = UIView
public typealias AppleColor = UIColor
public typealias AppleApplicationDelegate = UIResponder
public typealias AppleStoryboard = UIStoryboard
#else
import Cocoa
public typealias AppleView = NSView
public typealias AppleColor = NSColor
public typealias AppleApplicationDelegate = NSObject
public typealias AppleStoryboard = NSStoryboard
#endif

public typealias UnsafeMutableBufferFloatPointer = UnsafeMutableBufferPointer<Int32>

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Lambdas
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public typealias Func = () -> Void
public typealias FuncThrows = () throws -> Void
public typealias FuncReturningBool = () -> Bool
public typealias FuncReturningInt = () -> Int
public typealias FuncWithDouble = (Double) -> Void
