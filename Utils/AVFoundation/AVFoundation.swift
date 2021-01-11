
import AVFoundation

extension AVCaptureDevice.Format {
    
    var dimensions: CMVideoDimensions {
        get {
            return CMVideoFormatDescriptionGetDimensions(formatDescription)
        }
    }
    
    var mediaSubtype:FourCharCode {
        get {
            return CMFormatDescriptionGetMediaSubType(formatDescription)
        }
    }
}

extension AVCaptureDevice {

    static func defaultAudioDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.default(for: .audio)
    }

    static func defaultVideoDevice() -> AVCaptureDevice? {
        #if os(iOS)
        for i in AVCaptureDevice.devices(for: .video) {
            if i.position == .front {
                return i
            }
        }
        
        return nil
        #else
        return AVCaptureDevice.default(for: .video)
        #endif
    }
    
    func inputFormat(width: Int32) -> AVCaptureDevice.Format? {
        
        var result: AVCaptureDevice.Format? = nil
        var diff: Int32 = 0
        
        for i in formats {
            let i_diff = Int32(width) - i.dimensions.width

            if result == nil || abs(diff) > abs(i_diff) {
                result = i
                diff = i_diff
            }
        }
        
        return result
    }

    func inputFormat(height: Int32) -> AVCaptureDevice.Format? {
        
        var result: AVCaptureDevice.Format? = nil
        var diff: Int32 = 0
        
        for i in formats {
            let i_diff = Int32(height) - i.dimensions.height
            
            if result == nil || abs(diff) > abs(i_diff) {
                result = i
                diff = i_diff
            }
        }
        
        return result
    }
}

extension AVCaptureConnection {
    
    typealias Accessor = ((AVCaptureConnection) throws -> Void) throws -> Void
}

extension AVCaptureSession {
    
    typealias Accessor = ((AVCaptureSession) throws -> Void) throws -> Void
}

extension AVCaptureVideoOrientation {

    var isPortrait: Bool {
        get {
            return self == AVCaptureVideoOrientation.portrait || self == AVCaptureVideoOrientation.portraitUpsideDown
        }
    }
    
    var isLandscape: Bool {
        get {
            return self == AVCaptureVideoOrientation.landscapeLeft || self == AVCaptureVideoOrientation.landscapeRight
        }
    }
    
    func rotates(_ to: AVCaptureVideoOrientation) -> Bool {
        if self.isLandscape && to.isPortrait {
            return true
        }
        
        if self.isPortrait && to.isLandscape {
            return true
        }
        
        return false
    }
    
}

private class _AVCaptureVideoPreviewLayer : AVCaptureVideoPreviewLayer {
    
    override var session: AVCaptureSession! {
        didSet {
            setNeedsLayout()
        }
    }
}

class CaptureVideoPreviewView : AppleView {
    
    #if os(iOS)
    override open class var layerClass: Swift.AnyClass {
        return _AVCaptureVideoPreviewLayer.self
    }
    #else
    override func makeBackingLayer() -> CALayer {
        return _AVCaptureVideoPreviewLayer()
    }
    #endif
    
    var captureLayer: AVCaptureVideoPreviewLayer {
        get {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
}

func videoConnection(_ layer: AVCaptureVideoPreviewLayer) -> AVCaptureConnection.Accessor {
    return { (_ x: (AVCaptureConnection) throws -> Void) in
        guard let connection = layer.connection else { assert(false); return }
        try x(connection)
    }
}

func videoConnection(_ session: AVCaptureSession.Accessor?) -> AVCaptureConnection.Accessor? {
    return { (_ x: (AVCaptureConnection) throws -> Void) in
        try session?({ (_ session: AVCaptureSession) throws in
            guard let output = session.outputs.first else { return }
            guard let _ = output.connections.first else { return }
            guard let connection = output.connection(with: .video) else { assert(false); return }

            try x(connection)
        })
    }
}
