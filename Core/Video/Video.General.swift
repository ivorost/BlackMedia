
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

struct VideoEncoderConfig : Equatable {
    let codec: AVVideoCodecType
    let input: CMVideoDimensions
    let output: CMVideoDimensions

    init(codec: AVVideoCodecType, input: CMVideoDimensions, output: CMVideoDimensions) {
        self.codec = codec
        self.input = input
        self.output = output
    }
}


struct VideoBuffer {
    struct Flags: OptionSet {
        let rawValue: Int
        static let duplicate = Flags(rawValue: 1 << 0)
    }

    let sampleBuffer: CMSampleBuffer
    let flags: Flags
}


extension VideoBuffer {
    init(_ sampleBuffer: CMSampleBuffer) {
        self.init(sampleBuffer: sampleBuffer, flags: [])
    }
    
    func copy(flags: Flags) -> VideoBuffer {
        return VideoBuffer(sampleBuffer: sampleBuffer, flags: flags)
    }
}


protocol VideoOutputProtocol {
    func process(video: VideoBuffer)
}


protocol VideoOutputWithNextProtocol : VideoOutputProtocol {
    init(next: VideoOutputProtocol?)
}


class VideoProcessor : VideoOutputProtocol {
    
    private let next: VideoOutputProtocol?
    private let prev: VideoOutputProtocol?
    private let measure: MeasureProtocol?
    
    init(next: VideoOutputProtocol? = nil, measure: MeasureProtocol? = nil) {
        self.prev = nil
        self.next = next
        self.measure = measure
    }

    init(prev: VideoOutputProtocol, measure: MeasureProtocol? = nil) {
        self.prev = prev
        self.next = nil
        self.measure = measure
    }

    init(prev: VideoOutputProtocol, next: VideoOutputProtocol? = nil) {
        self.prev = prev
        self.next = next
        self.measure = nil
    }

    func process(video: VideoBuffer) {
        prev?.process(video: video)
        measure?.begin()
        let processNext = processSelf(video: video)
        measure?.end()
        if processNext { next?.process(video: video) }
    }
    
    func processSelf(video: VideoBuffer) -> Bool {
        // to override
        return true
    }
}


extension VideoProcessor {
    typealias Proto = VideoOutputProtocol

    public struct Kind : Hashable, Equatable, RawRepresentable {
        let rawValue: String
    }
}


class VideoOutputWithNext : VideoProcessor, VideoOutputWithNextProtocol {
    required init(next: VideoOutputProtocol?) {
        super.init(next: next)
    }
}


class VideoOutputDispatch : VideoOutputProtocol {
    let next: VideoOutputProtocol?
    let queue: DispatchQueue
    
    init(next: VideoOutputProtocol?, queue: DispatchQueue) {
        self.next = next
        self.queue = queue
    }
    
    func process(video: VideoBuffer) {
        if let next = next {
            queue.async {
                next.process(video: video)
            }
        }
    }
}


class VideoOutputBroadcast : VideoOutputProtocol {
    private let array: [VideoOutputProtocol?]
    
    init(_ array: [VideoOutputProtocol?]) {
        self.array = array
    }

    func process(video: VideoBuffer) {
        for i in array { i?.process(video: video) }
    }
}


func broadcast(_ x: [VideoOutputProtocol]) -> VideoOutputProtocol? {
    return broadcast(x, create: { VideoOutputBroadcast($0) })
}


protocol VideoSessionProtocol : SessionProtocol {
    
    func update(_ outputFormat: VideoConfig) throws
}


class VideoSession : Session, VideoSessionProtocol {

    private let next: VideoSessionProtocol?
   
    override init() {
        next = nil;
        super.init()
    }

    init(_ next: VideoSessionProtocol?, start: FuncThrows = {}, stop: Func = {}) {
        self.next = next;
        super.init(next)
    }

    func update(_ outputFormat: VideoConfig) throws {
        try next?.update(outputFormat)
    }
}


class VideoSessionBroadcast : Session.Broadcast, VideoSessionProtocol {
    
    private var x: [VideoSessionProtocol?]
    
    init(_ x: [VideoSessionProtocol?]) {
        self.x = x
        super.init(x)
    }
    
    func update(_ outputFormat: VideoConfig) throws {
        _ = try x.map({ try $0?.update(outputFormat) })
    }
}


func broadcast(_ x: [VideoSessionProtocol?]) -> VideoSessionProtocol? {
    return broadcast(x, create: { VideoSessionBroadcast($0) })
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
