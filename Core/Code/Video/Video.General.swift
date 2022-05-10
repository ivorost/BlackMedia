
import AVFoundation


public final class Video {}


extension Video {
    public static let defaultPixelFormat = kCVPixelFormatType_32BGRA
    public static let decoderQueue = DispatchQueue.CreateCheckable("decoder_queue")
}

extension Video {
    public struct Config : Equatable {
        
        typealias Factory = () throws -> Config

        let codec: AVVideoCodecType
        let fps: CMTime
        let dimensions: CMVideoDimensions

        init(codec: AVVideoCodecType, fps: CMTime, dimensions: CMVideoDimensions) {
            self.codec = codec
            self.fps = fps
            self.dimensions = dimensions
        }
        
        public static func ==(lhs: Config, rhs: Config) -> Bool {
            return lhs.fps == rhs.fps && lhs.dimensions == rhs.dimensions
        }

        public static func !=(lhs: Config, rhs: Config) -> Bool {
            return false == (lhs == rhs)
        }
        
        var width: Int32 {
            return dimensions.width
        }

        var height: Int32 {
            return dimensions.height
        }
    }
}


extension Video {
    public struct EncoderConfig : Equatable {
        let codec: AVVideoCodecType
        let input: CMVideoDimensions
        let output: CMVideoDimensions

        public init(codec: AVVideoCodecType, input: CMVideoDimensions, output: CMVideoDimensions) {
            self.codec = codec
            self.input = input
            self.output = output
        }
    }
}


extension Video {
    public struct Buffer {
        struct Flags: OptionSet {
            let rawValue: Int
            static let duplicate = Flags(rawValue: 1 << 0)
        }
        
        let ID: UInt
        let sampleBuffer: CMSampleBuffer
        let orientation: UInt8? // CGImagePropertyOrientation.
        let flags: Flags
    }
}


public extension Video.Buffer {
    init(ID: UInt, buffer: CMSampleBuffer, orientation: UInt8? = nil) {
        self.init(ID: ID, sampleBuffer: buffer, orientation: orientation, flags: [])
    }
}


extension Video.Buffer {
    func copy(flags: Flags) -> Video.Buffer {
        return Video.Buffer(ID: ID, sampleBuffer: sampleBuffer, orientation: orientation, flags: flags)
    }

    func copy(orientation: UInt8) -> Video.Buffer {
        return Video.Buffer(ID: ID, sampleBuffer: sampleBuffer, orientation: orientation, flags: flags)
    }
}
