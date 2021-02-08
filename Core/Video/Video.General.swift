
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

    let ID: UInt
    let sampleBuffer: CMSampleBuffer
    let orientation: UInt8? // CGImagePropertyOrientation.
    let flags: Flags
}


extension VideoBuffer {
    init(ID: UInt, buffer: CMSampleBuffer, orientation: UInt8? = nil) {
        self.init(ID: ID, sampleBuffer: buffer, orientation: orientation, flags: [])
    }
    
    func copy(flags: Flags) -> VideoBuffer {
        return VideoBuffer(ID: ID, sampleBuffer: sampleBuffer, orientation: orientation, flags: flags)
    }

    func copy(orientation: UInt8) -> VideoBuffer {
        return VideoBuffer(ID: ID, sampleBuffer: sampleBuffer, orientation: orientation, flags: flags)
    }
}


protocol VideoOutputProtocol {
    func process(video: VideoBuffer)
}


class VideoProcessorBase : VideoOutputProtocol {
    
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


class VideoProcessor : VideoProcessorBase {
    static let shared = VideoProcessor()
}


extension VideoProcessor {
    typealias Proto = VideoOutputProtocol
    typealias Base = VideoProcessorBase

    public struct Kind : Hashable, Equatable, RawRepresentable {
        let rawValue: String
    }
}


class VideoOutputDispatch : VideoOutputProtocol {
    let next: VideoOutputProtocol?
    let queue: OperationQueue
    
    init(next: VideoOutputProtocol?, queue: OperationQueue) {
        self.next = next
        self.queue = queue
    }
    
    func process(video: VideoBuffer) {
        if let next = next {
            queue.addOperation {
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
