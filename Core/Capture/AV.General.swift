
import AVFoundation

protocol DataProcessor : class {
    func process(data: Data)
}

class DataProcessorImpl : DataProcessor {
    private let prev: DataProcessor?
    private let next: DataProcessor?
    weak var nextWeak: DataProcessor? = nil


    init(next: DataProcessor? = nil) {
        self.prev = nil
        self.next = next
        self.nextWeak = next
    }

    init(prev: DataProcessor) {
        self.prev = prev
        self.next = nil
    }

    func process(data: Data) {
        prev?.process(data: data)
        nextWeak?.process(data: data)
    }
}

class DataProcessorBroadcast : DataProcessor {
    private var array: [DataProcessor?]
    
    init(_ array: [DataProcessor?]) {
        self.array = array
    }

    func process(data: Data) {
        for i in array { i?.process(data: data) }
    }
}

func broadcast(_ x: [DataProcessor?]) -> DataProcessor? {
    broadcast(x, create: { DataProcessorBroadcast($0) })
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Session
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typealias FuncWithSession = (SessionProtocol) -> Void
typealias FuncReturningSessionThrowing = () throws -> SessionProtocol

protocol SessionProtocol {
    func start () throws
    func stop()
}

class Session : SessionProtocol {
    private let next: SessionProtocol?
    private let startFunc: FuncThrows
    private let stopFunc: Func
    
    init() {
        next = nil
        startFunc = {}
        stopFunc = {}
    }
    
    init(_ next: SessionProtocol?, start: @escaping FuncThrows = {}, stop: @escaping Func = {}) {
        self.next = next
        self.startFunc = start
        self.stopFunc = stop
    }

    func start() throws {
        try startFunc()
        try next?.start()
    }

    func stop() {
        stopFunc()
        next?.stop()
    }
}

class SessionBroadcast : SessionProtocol {
    
    private var x: [SessionProtocol?]
    
    init(_ x: [SessionProtocol?]) {
        self.x = x
    }
    
    func start () throws {
        _ = try x.map({ try $0?.start() })
    }
    
    func stop() {
        _ = x.reversed().map({ $0?.stop() })
    }
}

class SessionSyncDispatch : SessionProtocol {
        
    let session: SessionProtocol
    let queue: DispatchQueue
    
    init(session: SessionProtocol, queue: DispatchQueue) {
        self.session = session
        self.queue = queue
    }
    
    func start () throws {
        try queue.sync {
            try session.start()
        }
    }
    
    func stop() {
        queue.sync {
            session.stop()
        }
    }
}


extension AVCaptureSession : SessionProtocol {
    func start() throws {
        startRunning()
    }
    
    func stop() {
        print("STOP CAPTURE")
        stopRunning()
    }
}


func broadcast(_ x: [SessionProtocol?]) -> SessionProtocol? {
    broadcast(x, create: { SessionBroadcast($0) })
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Config
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

struct CaptureConfig {
    let fileType: AVFileType
    
    let audioDevice: AVCaptureDevice
    let audioConfig: AudioConfig
    
    let videoDevice: AVCaptureDevice
    let videoFormat: AVCaptureDevice.Format
    let videoConfig: VideoConfig
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Settings
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

struct CaptureSettings {
    let data: [String: Any]
    
    init(_ data: [String: Any]) {
        self.data = data
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Progress
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

protocol CaptureProgress {
    var secondsAvailable: TimeInterval? { get }
    var secondsSinceStart: TimeInterval { get }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Logging
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

func logAV(_ message: String) {
    logMessage("IO", message)
}

func logAVPrior(_ message: String) {
    logPrior("IO", message)
}

func logAVError(_ error: Error) {
    logError("IO", error)
}

func logAVError(_ error: String) {
    logError("IO", error)
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Broadcast
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

func broadcast<T>(_ x: [T?], create: ([T]) -> T) -> T? {
    var theX = [T]()
    
    for i in x {
        if let i = i {
            theX.append(i)
        }
    }
    
    if (theX.count == 0) {
        return nil
    }
    if (theX.count == 1) {
        return theX[0]
    }
    
    return create(theX)
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Broadcast
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

enum CaptureError : Error {
    case status(code: OSStatus, message: String)
}

func checkStatus(_ status: OSStatus, _ message: String) throws {
    guard status == 0 else {
        throw CaptureError.status(code: status, message: message)
    }
}
