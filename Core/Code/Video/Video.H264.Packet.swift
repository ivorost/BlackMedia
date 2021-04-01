
import AVFoundation


public extension VideoProcessor {
    struct Packet {
        let ID: UInt
        let time: VideoTime
        let originalTime: VideoTime
        let orientation: UInt8
    }
    
    struct PacketH264 {
        let metadata: Packet
        let sps: Data
        let pps: Data
        let data: Data
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VideoH264Serializer
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class VideoH264Serializer : PacketSerializer.Processor, VideoOutputProtocol {
    private var timebase: VideoTime?
    
    func process(video: VideoBuffer) {
        let formatDescription: CMFormatDescription = CMSampleBufferGetFormatDescription(video.sampleBuffer)!
        
        if CMSampleBufferGetNumSamples(video.sampleBuffer) != 1 {
            logAVError("CMSampleBufferGetNumSamples should be equal to one")
            return
        }
        
        // timing info
        
        var timingInfo = CMSampleTimingInfo()
        
        if CMSampleBufferGetSampleTimingInfo(video.sampleBuffer,
                                             at: 0,
                                             timingInfoOut: &timingInfo) != 0 {
            logAVError("CMSampleBufferGetSampleTimingInfo failed")
            return
        }
        
        // H264 description (SPS)
        
        var sps: UnsafePointer<UInt8>?
        var spsLength: Int = 0
        var count: Int = 0
        
        if CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDescription,
                                                              parameterSetIndex: 0,
                                                              parameterSetPointerOut: &sps,
                                                              parameterSetSizeOut: &spsLength,
                                                              parameterSetCountOut: &count,
                                                              nalUnitHeaderLengthOut: nil) != 0 {
            logAVError("An Error occured while getting h264 sps parameter")
            return
        }
        
        if count != 2 {
            logAVError("SPS and PPS count should be equal to two")
            return
        }

        assert(count == 2) // sps and pps
        
        // H264 description (PPS)
        
        var pps: UnsafePointer<UInt8>?
        var ppsLength: Int = 0
        
        if CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDescription,
                                                              parameterSetIndex: 1,
                                                              parameterSetPointerOut: &pps,
                                                              parameterSetSizeOut: &ppsLength,
                                                              parameterSetCountOut: &count,
                                                              nalUnitHeaderLengthOut: nil) != 0 {
            logAVError("An Error occured while getting h264 pps parameter")
            return
        }
        
        if count != 2 {
            logAVError("PPS and SPS count should be equal to two")
            return
        }

        // H264 data
        
        let blockBuffer = CMSampleBufferGetDataBuffer(video.sampleBuffer)
        var totalLength = Int()
        var length = Int()
        var dataPointer: UnsafeMutablePointer<Int8>? = nil
        
        if CMBlockBufferGetDataPointer(blockBuffer!,
                                       atOffset: 0,
                                       lengthAtOffsetOut: &length,
                                       totalLengthOut: &totalLength,
                                       dataPointerOut: &dataPointer) != 0 {
            logAVError("CMBlockBufferGetDataPointer failed")
            return
        }
        
        if length != totalLength {
            logAVError("length and totalLength should be equal")
            return
        }
        
        // reset to to relative
        
        let systemTime = VideoTime(timingInfo)
        var videoTime = VideoTime(timingInfo)
        
        if timebase == nil {
            timebase = videoTime
        }
        
        if let timebase = timebase {
            videoTime = videoTime.relative(to: timebase)
        }
        
        // build data
        
        let serializer = PacketSerializer(.video)

        serializer.push(value: UInt64(video.ID))
        serializer.push(data: videoTime.data)
        serializer.push(data: systemTime.data)
        serializer.push(value: UInt8(video.orientation ?? 0))
        serializer.push(data: Data(bytes: sps!, count: spsLength))
        serializer.push(data: Data(bytes: pps!, count: ppsLength))
        serializer.push(data: Data(bytes: dataPointer!, count: Int(totalLength)))
        
        process(packet: serializer)
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Serializer Setup
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public class VideoSetupSerializerH264 : VideoSetupSlave {
    private let kind: VideoProcessor.Kind
    
    public init(root: VideoSetupProtocol, kind: VideoProcessor.Kind) {
        self.kind = kind
        super.init(root: root)
    }
    
    public override func video(_ video: VideoProcessor.Proto, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        var result = video

        if kind == self.kind {
            let serializerData = root.data(DataProcessor.shared, kind: .serializer)
            let serializer = VideoH264Serializer(next: serializerData)
            
            result = VideoProcessor(prev: result, next: serializer)
        }

        return super.video(result, kind: kind)
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NetworkH264Deserializer
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public class VideoH264DeserializerBase : PacketDeserializer.Processor {
    private let metadataOnly: Bool
    
    public init(metadataOnly: Bool = false) {
        self.metadataOnly = metadataOnly
        super.init(type: .video)
    }

    public override func process(packet: PacketDeserializer) {
        var ID64: UInt64 = 0; packet.pop(&ID64)
        let ID = UInt(ID64)
        let time = VideoTime(deserialize: packet.popData()) // zero based timestamp
        let timeOriginal = VideoTime(deserialize: packet.popData()) // system clock based timestamp
        var orientation: UInt8 = 0; packet.pop(&orientation)
        let metadata = VideoProcessor.Packet(ID: ID, time: time, originalTime: timeOriginal, orientation: orientation)
        

        process(metadata: metadata)

        if !metadataOnly {
            let sps  = packet.popData()
            let pps  = packet.popData()
            let data = packet.popData()
            
            process(h264: VideoProcessor.PacketH264(metadata: metadata, sps: sps, pps: pps, data: data))
        }
    }
    
    func process(metadata: VideoProcessor.Packet) {
        
    }
    
    func process(h264: VideoProcessor.PacketH264) {
        
    }
}


class VideoH264Deserializer : VideoH264DeserializerBase {
    private let next: VideoOutputProtocol?

    init(next: VideoOutputProtocol?) {
        self.next = next
        super.init()
    }

    override func process(h264: VideoProcessor.PacketH264) {
        do {
            let h264SPS  = h264.sps as NSData
            let h264PPS  = h264.pps as NSData
            var timingInfo = h264.metadata.time.cmSampleTimingInfo

//            print("deserializer \(ID)")
            
            // format description
            
            var formatDescription: CMFormatDescription?
            
            let parameterSetPointers : [UnsafePointer<UInt8>] = [h264SPS.bytes.assumingMemoryBound(to: UInt8.self),
                                                                 h264PPS.bytes.assumingMemoryBound(to: UInt8.self)]
            let parameterSetSizes : [Int] = [h264SPS.count,
                                             h264PPS.count]
            
            try check(status: CMVideoFormatDescriptionCreateFromH264ParameterSets(
                        allocator: kCFAllocatorDefault,
                        parameterSetCount: 2,
                        parameterSetPointers: parameterSetPointers,
                        parameterSetSizes: parameterSetSizes,
                        nalUnitHeaderLength: 4,
                        formatDescriptionOut: &formatDescription),
                      message: "CMVideoFormatDescriptionCreateFromH264ParameterSets failed")
            
            // block buffer
            
            var blockBuffer: CMBlockBuffer?
            let blockBufferData = UnsafeMutablePointer<Int8>.allocate(capacity: h264.data.count)
            
            h264.data.bytes {
                blockBufferData.assign(from: $0.assumingMemoryBound(to: Int8.self), count: h264.data.count)
            }
            
            try check(status: CMBlockBufferCreateWithMemoryBlock(
                        allocator: kCFAllocatorDefault,
                        memoryBlock: blockBufferData,
                        blockLength: h264.data.count,
                        blockAllocator: kCFAllocatorDefault,
                        customBlockSource: nil,
                        offsetToData: 0,
                        dataLength: h264.data.count,
                        flags: 0,
                        blockBufferOut: &blockBuffer),
                      message: "createReadonlyBlockBuffer")
            
            // sample buffer
            
            var result : CMSampleBuffer?
            try check(status: CMSampleBufferCreateReady(
                        allocator: kCFAllocatorDefault,
                        dataBuffer: blockBuffer,
                        formatDescription: formatDescription,
                        sampleCount: 1,
                        sampleTimingEntryCount: 1,
                        sampleTimingArray: &timingInfo,
                        sampleSizeEntryCount: 0,
                        sampleSizeArray: nil,
                        sampleBufferOut: &result),
                      message: "CMSampleBufferCreateReady failed")
            
            // output
            
            next?.process(video: VideoBuffer(ID: h264.metadata.ID,
                                             buffer: result!,
                                             orientation: h264.metadata.orientation))
        }
        catch {
            logAVError(error)
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deserializer Setup
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public class VideoSetupDeserializerH264 : VideoSetupSlave {
    private let kind: DataProcessor.Kind
    
    public init(root: VideoSetupProtocol, kind: DataProcessor.Kind) {
        self.kind = kind
        super.init(root: root)
    }
    
    public override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        var result = data
        
        if kind == self.kind {
            let deserializerVideo = root.video(VideoProcessor(), kind: .deserializer)
            let deserializer = root.data(VideoH264Deserializer(next: deserializerVideo), kind: .deserializer)
            result = DataProcessor(prev: result, next: deserializer)
        }
        
        return super.data(result, kind: kind)
    }
}
