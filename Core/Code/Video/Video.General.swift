
import AVFoundation


public struct VideoConfig : Equatable {
    
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

public struct VideoEncoderConfig : Equatable {
    let codec: AVVideoCodecType
    let input: CMVideoDimensions
    let output: CMVideoDimensions

    public init(codec: AVVideoCodecType, input: CMVideoDimensions, output: CMVideoDimensions) {
        self.codec = codec
        self.input = input
        self.output = output
    }
}


public struct VideoBuffer {
    struct Flags: OptionSet {
        let rawValue: Int
        static let duplicate = Flags(rawValue: 1 << 0)
    }

    let ID: UInt
    let sampleBuffer: CMSampleBuffer
    let orientation: UInt8? // CGImagePropertyOrientation.
    let flags: Flags
}


public extension VideoBuffer {
    init(ID: UInt, buffer: CMSampleBuffer, orientation: UInt8? = nil) {
        self.init(ID: ID, sampleBuffer: buffer, orientation: orientation, flags: [])
    }
}

extension VideoBuffer {
    func copy(flags: Flags) -> VideoBuffer {
        return VideoBuffer(ID: ID, sampleBuffer: sampleBuffer, orientation: orientation, flags: flags)
    }

    func copy(orientation: UInt8) -> VideoBuffer {
        return VideoBuffer(ID: ID, sampleBuffer: sampleBuffer, orientation: orientation, flags: flags)
    }
}


public protocol VideoOutputProtocol {
    func process(video: VideoBuffer)
}


public class VideoProcessorBase : VideoOutputProtocol {
    
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

    public func process(video: VideoBuffer) {
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


public class VideoProcessor : VideoProcessorBase {
    static let shared = VideoProcessor()
}


public extension VideoProcessor {
    typealias Proto = VideoOutputProtocol
    typealias Base = VideoProcessorBase

    struct Kind : Hashable, Equatable, RawRepresentable {
        public init(rawValue: String) { self.rawValue = rawValue }
        public let rawValue: String
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


public func broadcast(_ x: [VideoOutputProtocol]) -> VideoOutputProtocol? {
    return broadcast(x, create: { VideoOutputBroadcast($0) })
}


public protocol VideoSessionProtocol : SessionProtocol {
    
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


public func broadcast(_ x: [VideoSessionProtocol?]) -> VideoSessionProtocol? {
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
