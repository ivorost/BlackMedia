
import AVFoundation

protocol DataProcessor {
    func process(data: NSData)
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Session
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

typealias FuncWithSession = (SessionProtocol) -> Void

protocol SessionProtocol {
    func start () throws
    func stop()
}

class Session : SessionProtocol {
    private let next: SessionProtocol?
    init() { next = nil }
    init(_ next: SessionProtocol?) { self.next = next }
    func start() throws { try next?.start() }
    func stop() { next?.stop() }
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


func broadcast(_ x: [SessionProtocol]) -> SessionProtocol? {
    broadcast(x, create: { SessionBroadcast(x) })
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

func broadcast<T>(_ x: [T?], create: () -> T?) -> T? {
    if (x.count == 0) {
        return nil
    }
    if (x.count == 1) {
        return x[0]
    }
    
    return create()
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
