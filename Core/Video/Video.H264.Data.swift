
import AVFoundation


extension PacketDeserializer {
    
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

        serializer.push(data: videoTime.data)
        serializer.push(data: systemTime.data)
        serializer.push(data: Data(bytes: sps!, count: spsLength))
        serializer.push(data: Data(bytes: pps!, count: ppsLength))
        serializer.push(data: Data(bytes: dataPointer!, count: Int(totalLength)))

        process(packet: serializer)
        
        print("video \(serializer.data.count)")
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NetworkH264Deserializer
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class VideoH264DeserializerBase : PacketDeserializer.Processor {
    private let metadataOnly: Bool
    
    init(metadataOnly: Bool = false) {
        self.metadataOnly = metadataOnly
        super.init(type: .video)
    }

    override func process(packet: PacketDeserializer) {
        let time = VideoTime(deserialize: packet.popData()) // zero based timestamp
        let timeOriginal = VideoTime(deserialize: packet.popData()) // system clock based timestamp
        
        process(time: time, originalTime: timeOriginal)

        if !metadataOnly {
            let h264SPS  = packet.popData()
            let h264PPS  = packet.popData()
            let h264Data = packet.popData()
            
            process(h264: h264Data, sps: h264SPS, pps: h264PPS, time: time, originalTime: timeOriginal)
        }
    }
    
    func process(time: VideoTime, originalTime: VideoTime) {
    }
    
    func process(h264: Data, sps: Data, pps: Data, time: VideoTime, originalTime: VideoTime) {
    }
}


class VideoH264Deserializer : VideoH264DeserializerBase {
    private let next: VideoOutputProtocol?

    init(next: VideoOutputProtocol?) {
        self.next = next
        super.init()
    }

    override func process(h264: Data, sps: Data, pps: Data, time: VideoTime, originalTime: VideoTime) {
        do {
            let h264SPS  = sps as NSData
            let h264PPS  = pps as NSData
            var timingInfo = time.cmSampleTimingInfo

            // format description
            
            var formatDescription: CMFormatDescription?
            
            let parameterSetPointers : [UnsafePointer<UInt8>] = [h264SPS.bytes.assumingMemoryBound(to: UInt8.self),
                                                                 h264PPS.bytes.assumingMemoryBound(to: UInt8.self)]
            let parameterSetSizes : [Int] = [h264SPS.count,
                                             h264PPS.count]
            
            try checkStatus(CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault,
                                                                                parameterSetCount: 2,
                                                                                parameterSetPointers: parameterSetPointers,
                                                                                parameterSetSizes: parameterSetSizes,
                                                                                nalUnitHeaderLength: 4,
                                                                                formatDescriptionOut: &formatDescription),
                            "CMVideoFormatDescriptionCreateFromH264ParameterSets failed")
            
            // block buffer
            
            var blockBuffer: CMBlockBuffer?
            let blockBufferData = UnsafeMutablePointer<Int8>.allocate(capacity: h264.count)
            
            h264.bytes {
                blockBufferData.assign(from: $0.assumingMemoryBound(to: Int8.self), count: h264.count)
            }
            
            try checkStatus(CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
                                                               memoryBlock: blockBufferData,
                                                               blockLength: h264.count,
                                                               blockAllocator: kCFAllocatorDefault,
                                                               customBlockSource: nil,
                                                               offsetToData: 0,
                                                               dataLength: h264.count,
                                                               flags: 0,
                                                               blockBufferOut: &blockBuffer), "createReadonlyBlockBuffer")
            
            // sample buffer
            
            var result : CMSampleBuffer?
            try checkStatus(CMSampleBufferCreateReady(allocator: kCFAllocatorDefault,
                                                      dataBuffer: blockBuffer,
                                                      formatDescription: formatDescription,
                                                      sampleCount: 1,
                                                      sampleTimingEntryCount: 1,
                                                      sampleTimingArray: &timingInfo,
                                                      sampleSizeEntryCount: 0,
                                                      sampleSizeArray: nil,
                                                      sampleBufferOut: &result), "CMSampleBufferCreateReady failed")
            
            // output
            
            next?.process(video: VideoBuffer(result!))
        }
        catch {
            logAVError(error)
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deserializer Setup
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class VideoSetupDeserializerH264 : VideoSetupSlave {
    private let kind: DataProcessor.Kind
    
    init(root: VideoSetupProtocol, kind: DataProcessor.Kind) {
        self.kind = kind
        super.init(root: root)
    }
    
    override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        var result = data
        
        if kind == self.kind {
            let deserializerVideo = root.video(VideoProcessor(), kind: .deserializer)
            let deserializer = root.data(VideoH264Deserializer(next: deserializerVideo), kind: .deserializer)
            result = DataProcessor(prev: result, next: deserializer)
        }
        
        return super.data(result, kind: kind)
    }
}
