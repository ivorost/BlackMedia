
import Foundation

public protocol InitProtocol {
    init()
}

public func typeName(_ some: Any) -> String {
    return (some is Any.Type) ? "\(some)" : "\(type(of: some))"
}

public func factory<T>(_ src: T) -> () -> T {
    return { return src }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Device
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public func deviceModel() -> String {
    var size = 0
    sysctlbyname("hw.machine", nil, &size, nil, 0)
    var machine = [CChar](repeating: 0,  count: size)
    sysctlbyname("hw.machine", &machine, &size, nil, 0)
    return String(cString: machine)
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Time
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public class HostTimeInfo {
    static let shared = HostTimeInfo()
    
    let numer: UInt32
    let denom: UInt32
    let zero: UInt64
    
    init() {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        
        numer = info.numer
        denom = info.denom
        zero = mach_absolute_time()
    }
}

public func seconds2nano(_ seconds: Double) -> Int64 {
    return nano(seconds)
}

public func seconds4nano(_ nano: Int64) -> Double {
    return Double(nano) / 1000000000.0
}

public func milli(_ x: Double) -> Int64 {
    return Int64(x * 1000.0)
}

public func micro(_ x: Double) -> Int64 {
    return Int64(x * 1000.0 * 1000.0)
}

public func nano(_ x: Double) -> Int64 {
    return Int64(x * 1000.0 * 1000.0 * 1000.0)
}

public func mach_absolute_seconds(_ machTime: UInt64) -> Double {
    return
        seconds4nano(
            Int64(Double(machTime * UInt64(HostTimeInfo.shared.numer)) / Double(HostTimeInfo.shared.denom)))
}

public func mach_absolute_seconds() -> Double {
    return mach_absolute_seconds(mach_absolute_time())
}

public func mach_absolute_time(seconds: Double) -> UInt64 {
    return
        UInt64(seconds2nano(
            seconds * Double(HostTimeInfo.shared.denom) / Double(HostTimeInfo.shared.numer)))
}

public func app_absolute_seconds() -> Double {
    return mach_absolute_seconds() - mach_absolute_seconds(HostTimeInfo.shared.zero)
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Data
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public extension NSData {
    typealias Factory = () throws -> NSData
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Stream
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public extension OutputStream {
    
    func write(_ x: String) {
        guard let data = x.data(using: .utf8) as NSData? else { assert(false); return }
        write(UnsafePointer<UInt8>(OpaquePointer(data.bytes)), maxLength: data.length)
    }
}
