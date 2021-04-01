
import Foundation

fileprivate class _Label {
    
    let x: String
    
    init(_ x: String) {
        self.x = x
    }
    
}

public extension DispatchQueue {

    fileprivate static let keyID = DispatchSpecificKey<_Label>()

    static func CreateCheckable(_ label: String) -> DispatchQueue {
        let result = DispatchQueue(label: label)
        result.setSpecific(key: DispatchQueue.keyID, value: _Label(label))
        return result
    }

    static func OnQueue(_ x: DispatchQueue) -> Bool {
        return DispatchQueue.getSpecific(key: DispatchQueue.keyID)?.x == x.label
    }
    
    func asyncAfter0_5(_ block: @escaping Func) {
        asyncAfter(deadline: .now() + 5) {
            block()
        }
    }
    
    var isCurrent: Bool {
        return DispatchQueue.OnQueue(self)
    }
}

public func assert(_ onQueue: DispatchQueue) {
    assert(DispatchQueue.OnQueue(onQueue))
}

public func dispatch_sync_on_main(execute block: () -> Swift.Void) {
    if Thread.isMainThread {
        block()
    }
    else {
        DispatchQueue.main.sync { block() }
    }
}

public func dispatch_sync_on_main(execute block: () throws -> Swift.Void) throws {
    if Thread.isMainThread {
        try block()
    }
    else {
        try DispatchQueue.main.sync { try block() }
    }
}
