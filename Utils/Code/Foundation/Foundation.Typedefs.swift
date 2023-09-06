
import Foundation

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Typedefs
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public typealias UnsafeMutableBufferFloatPointer = UnsafeMutableBufferPointer<Int32>

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Lambdas
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public typealias Func = () -> Void
public typealias FuncThrows = () throws -> Void
public typealias FuncReturningBool = () -> Bool
public typealias FuncReturningInt = () -> Int
public typealias FuncWithDouble = (Double) -> Void
