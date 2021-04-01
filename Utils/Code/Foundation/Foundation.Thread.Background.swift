
import Foundation

public extension Double {
    static let defaultInterval: Double = 0.1
}

public class BackgroundThread : Thread {
    
    private var runLoop: RunLoop!
    private var callbacks = [UUID: FuncThrows]()
    private var errors = [UUID: Error]()
    private var running: Bool = false
    private var interval: Double
    
    public init(_ name: String, interval: Double = .defaultInterval) {
        self.interval = interval
        super.init()
        self.name = name
    }
    
    public convenience init<T>(_ type: T, interval: Double = .defaultInterval) {
        if let typeName = type as? String {
            self.init(typeName)
        }
        else {
            self.init(typeName(type))
        }
    }
    
    override public func main() {
        runLoop = RunLoop.current
        runLoop!.add(NSMachPort(), forMode: .default)
        running = true
        
        while running {
            autoreleasepool {
                runLoop!.run(until: Date().addingTimeInterval(interval))
            }
        }
    }
    
    override public func start() {
        autoreleasepool {
            super.start()
            sync { /* wait for RunLoop initialization */ }
        }
    }
    
    override public func cancel() {
        running = false
        super.cancel()
    }
    
    public func sync(_ callback: @escaping Func) {
        try? _sync(callback)
    }

    public func sync(_ callback: @escaping FuncThrows) throws {
        try _sync(callback)
    }
    
    private func _sync(_ callback: @escaping FuncThrows) throws {
        if Thread.current == self {
            try autoreleasepool {
                try callback()
            }
        }
        else {
            try _call(callback, true)
        }
    }

    public func async(_ callback: @escaping Func) {
        try? _call(callback, false)
    }
    
    public func exec(sync: Bool, _ callback: @escaping Func) {
        if sync {
            self.sync(callback)
        }
        else {
            self.async(callback)
        }
    }
    
    func _call(_ callback: @escaping FuncThrows, _ wait: Bool) throws {
        let id = UUID()
        
        callbacks[id] = callback
        
        perform(#selector(_perform(_:)),
                on: self,
                with: id,
                waitUntilDone: wait)
        
        if wait, let error = errors[id] {
            errors.removeValue(forKey: id)
            throw error
        }
    }

    @objc func _perform(_ id: UUID) {
        autoreleasepool {
            do {
                try callbacks[id]!()
            }
            catch {
                errors[id] = error
            }
            
            callbacks.removeValue(forKey: id)
        }
    }
}
