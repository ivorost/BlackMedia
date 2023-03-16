
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

public struct Device {
    private struct InterfaceNames {
        static let wifi = ["en0"]
        static let wired = ["en2", "en3", "en4"]
        static let cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]
        static let supported = wifi + wired + cellular
    }

    public struct NetworkInterfaceInfo {
        public let name: String
        public let ip: String
        public let netmask: String
    }

    public static var model: String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0,  count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }

    #if !canImport(UIKit)
    public static var name: String {
        Host.current().localizedName ?? "Unknown device"
    }
    #endif

    public static var internet: NetworkInterfaceInfo? {
        return interfaces.first { InterfaceNames.supported.contains($0.name) }
    }

    public static var internetIP: String? {
        return internet?.ip
    }

    public static var wifi: NetworkInterfaceInfo? {
        return interfaces.first { $0.name == InterfaceNames.wifi.first }
    }

    public static var wifiIP: String? {
        return wifi?.ip
    }

    public static var interfaces: [NetworkInterfaceInfo] {
        var interfaces = [NetworkInterfaceInfo]()

        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {

            // For each interface ...
            var ptr = ifaddr
            while( ptr != nil) {

                let flags = Int32(ptr!.pointee.ifa_flags)
                var addr = ptr!.pointee.ifa_addr.pointee

                // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {

                        var mask = ptr!.pointee.ifa_netmask.pointee

                        // Convert interface address to a human readable string:
                        let zero  = CChar(0)
                        var hostname = [CChar](repeating: zero, count: Int(NI_MAXHOST))
                        var netmask =  [CChar](repeating: zero, count: Int(NI_MAXHOST))
                        if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                        nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                            let address = String(cString: hostname)
                            let name = ptr!.pointee.ifa_name!
                            let ifname = String(cString: name)


                            if (getnameinfo(&mask, socklen_t(mask.sa_len), &netmask, socklen_t(netmask.count),
                                            nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                                let netmaskIP = String(cString: netmask)

                                let info = NetworkInterfaceInfo(name: ifname,
                                                                ip: address,
                                                                netmask: netmaskIP)
                                interfaces.append(info)
                            }
                        }
                    }
                }
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return interfaces
    }

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
