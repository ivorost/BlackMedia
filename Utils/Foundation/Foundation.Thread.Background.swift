
import Foundation

extension Double {
    static let defaultInterval: Double = 0.1
}

class BackgroundThread : Thread {
    
    private var runLoop: RunLoop!
    private var callbacks = [UUID: Func]()
    private var running: Bool = false
    private var interval: Double
    
    init(_ name: String, interval: Double = .defaultInterval) {
        self.interval = interval
        super.init()
        self.name = name
    }
    
    convenience init<T>(_ type: T, interval: Double = .defaultInterval) {
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
    
    func sync(_ callback: @escaping Func) {
        if Thread.current == self {
            autoreleasepool {
                callback()
            }
        }
        else {
            _call(callback, true)
        }
    }

    func async(_ callback: @escaping Func) {
        _call(callback, false)
    }
    
    func exec(sync: Bool, _ callback: @escaping Func) {
        if sync {
            self.sync(callback)
        }
        else {
            self.async(callback)
        }
    }
    
    func _call(_ callback: @escaping Func, _ wait: Bool) {
        let id = UUID()
        
        callbacks[id] = callback
        
        perform(#selector(_perform(_:)),
                on: self,
                with: id,
                waitUntilDone: wait)
    }

    @objc func _perform(_ id: UUID) {
        autoreleasepool {
            callbacks[id]!()
            callbacks.removeValue(forKey: id)
        }
    }
}
