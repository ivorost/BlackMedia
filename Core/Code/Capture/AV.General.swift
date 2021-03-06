
import AVFoundation


public class Timebase : Session {
    private(set) var date: Date = Date()
    
    public override func start() throws {
        date = Date()
    }
}


public extension Session.Kind {
    static let avCapture = Session.Kind(rawValue: "avCapture")
    static let encoder = Session.Kind(rawValue: "encoder")
}


extension AVCaptureSession : SessionProtocol {
    public func start() throws {
        startRunning()
    }
    
    public func stop() {
        print("STOP CAPTURE")
        stopRunning()
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Config
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public struct CaptureConfig {
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

public struct CaptureSettings {
    let data: [String: Any]
    
    init(_ data: [String: Any]) {
        self.data = data
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Progress
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public protocol CaptureProgress {
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

public func logAVError(_ error: Error) {
    logError("IO", error)
}

public func logAVError(_ error: String) {
    logError("IO", error)
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Broadcast
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public func broadcast<T>(_ x: [T?], create: ([T]) -> T) -> T? {
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
