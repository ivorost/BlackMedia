
import Foundation

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Typedefs
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if os(iOS)
    import UIKit
    typealias AppleView = UIView
    typealias AppleColor = UIColor
    typealias AppleApplicationDelegate = UIResponder
    typealias AppleStoryboard = UIStoryboard
#else
    import Cocoa
    typealias AppleView = NSView
    typealias AppleColor = NSColor
    typealias AppleApplicationDelegate = NSObject
    typealias AppleStoryboard = NSStoryboard
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Lambdas
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public typealias Func = () -> Void
public typealias FuncThrows = () throws -> Void
public typealias FuncReturningBool = () -> Bool
public typealias FuncVVT = () throws -> Void
public typealias FuncDV = (Double) -> Void
public typealias FuncDDV = (Double, Double) -> Void