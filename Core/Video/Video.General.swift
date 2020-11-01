
import AVFoundation


struct VideoConfig : Equatable {
    
    typealias Factory = () throws -> VideoConfig

    let codec: AVVideoCodecType
    let fps: CMTime
    let dimensions: CMVideoDimensions

    init(codec: AVVideoCodecType, fps: CMTime, dimensions: CMVideoDimensions) {
        self.codec = codec
        self.fps = fps
        self.dimensions = dimensions
    }
    
    public static func ==(lhs: VideoConfig, rhs: VideoConfig) -> Bool {
        return lhs.fps == rhs.fps && lhs.dimensions == rhs.dimensions
    }

    public static func !=(lhs: VideoConfig, rhs: VideoConfig) -> Bool {
        return false == (lhs == rhs)
    }
    
    var width: Int32 {
        return dimensions.width
    }

    var height: Int32 {
        return dimensions.height
    }
}


protocol VideoOutputProtocol {
    
    func process(video: CMSampleBuffer)
}


class VideoOutputImpl : VideoOutputProtocol {
    
    var next: VideoOutputProtocol?
    var measure: MeasureProtocol?
    
    init(next: VideoOutputProtocol? = nil, measure: MeasureProtocol? = nil) {
        self.next = next
        self.measure = measure
    }
    
    func process(video: CMSampleBuffer) {
        measure?.begin()
        let processNext = processSelf(video: video)
        measure?.end()
        if processNext { next?.process(video: video) }
    }
    
    func processSelf(video: CMSampleBuffer) -> Bool {
        // to override
        return true
    }
}


protocol VideoSessionProtocol : SessionProtocol {
    
    func update(_ outputFormat: VideoConfig) throws
}


class VideoSession : Session, VideoSessionProtocol {

    private let next: VideoSessionProtocol?
    override init() { next = nil; super.init() }
    init(_ next: VideoSessionProtocol?) { self.next = next; super.init(next) }
    func update(_ outputFormat: VideoConfig) throws { try next?.update(outputFormat) }
}


class VideoSessionBroadcast : SessionBroadcast, VideoSessionProtocol {
    
    private var x: [VideoSessionProtocol?]
    
    init(_ x: [VideoSessionProtocol?]) {
        self.x = x
        super.init(x)
    }
    
    func update(_ outputFormat: VideoConfig) throws {
        _ = try x.map({ try $0?.update(outputFormat) })
    }
}


func broadcast(_ x: [VideoSessionProtocol]) -> VideoSessionProtocol? {
    if (x.count == 0) {
        return nil
    }
    if (x.count == 1) {
        return x.first
    }
    
    return VideoSessionBroadcast(x)
}


extension CaptureSettings {
    static func video(config: VideoConfig) -> CaptureSettings {
        var result = [String: Any]()
        
        result[AVVideoWidthKey] = Int(config.width)
        result[AVVideoHeightKey] = Int(config.height)
        result[AVVideoCodecKey] = config.codec

        return CaptureSettings(result)
    }
}
