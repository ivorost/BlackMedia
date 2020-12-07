
import AVFoundation

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VideoH264Serializer
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class VideoH264Serializer : PacketSerializer.Processor, VideoOutputProtocol {
    private var timebase: VideoTime?
    
    func process(video: CMSampleBuffer) {
        let formatDescription: CMFormatDescription = CMSampleBufferGetFormatDescription(video)!
        
        if CMSampleBufferGetNumSamples(video) != 1 {
            logAVError("CMSampleBufferGetNumSamples should be equal to one")
            return
        }
        
        // timing info
        
        var timingInfo = CMSampleTimingInfo()
        
        if CMSampleBufferGetSampleTimingInfo(video,
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
        
        let blockBuffer = CMSampleBufferGetDataBuffer(video)
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
        serializer.push(data: Data(bytes: sps!, count: spsLength))
        serializer.push(data: Data(bytes: pps!, count: ppsLength))
        serializer.push(data: Data(bytes: dataPointer!, count: Int(totalLength)))

        process(packet: serializer)
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NetworkH264Deserializer
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class VideoH264Deserializer : DataProcessorProtocol {
    
    private let next: VideoOutputProtocol?
    private var prevTime: CMSampleTimingInfo?
    private var firstTime: CMSampleTimingInfo?
    private var startDate: Date?
    
    init(_ next: VideoOutputProtocol?) {
        self.next = next
    }
    
    func process(data: Data) {
        let d = PacketDeserializer(data)
        
        guard d.type == .video else { return }
        
        let h264Time = d.popData()
        let h264SPS  = d.popData() as NSData
        let h264PPS  = d.popData() as NSData
        let h264Data = d.popData()
        
        do {
            var timingInfo = VideoTime(deserialize: h264Time).cmSampleTimingInfo

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
            let blockBufferData = UnsafeMutablePointer<Int8>.allocate(capacity: h264Data.count)
            
            h264Data.bytes {
                blockBufferData.assign(from: $0.assumingMemoryBound(to: Int8.self), count: h264Data.count)
            }
            
            try checkStatus(CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
                                                               memoryBlock: blockBufferData,
                                                               blockLength: h264Data.count,
                                                               blockAllocator: kCFAllocatorDefault,
                                                               customBlockSource: nil,
                                                               offsetToData: 0,
                                                               dataLength: h264Data.count,
                                                               flags: 0,
                                                               blockBufferOut: &blockBuffer), "createReadonlyBlockBuffer")
            
            // sample buffer
            
            var sampleBuffer : CMSampleBuffer?
            try checkStatus(CMSampleBufferCreateReady(allocator: kCFAllocatorDefault,
                                                      dataBuffer: blockBuffer,
                                                      formatDescription: formatDescription,
                                                      sampleCount: 1,
                                                      sampleTimingEntryCount: 1,
                                                      sampleTimingArray: &timingInfo,
                                                      sampleSizeEntryCount: 0,
                                                      sampleSizeArray: nil,
                                                      sampleBufferOut: &sampleBuffer), "CMSampleBufferCreateReady failed")
            
            // output
            
            next?.process(video: sampleBuffer!)
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
            let deserializer = root.data(VideoH264Deserializer(deserializerVideo), kind: .deserializer)
            result = DataProcessor(prev: result, next: deserializer)
        }
        
        return super.data(result, kind: kind)
    }
}
