
import AVFoundation

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VideoH264Serializer
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class VideoH264Serializer : VideoOutputProtocol {
    
    private var byterate = Byterate(print: true)
    private var next: DataProcessor?
    
    init(_ next: DataProcessor?) {
        self.next = next
    }
    
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
        
        // build data
        
        let serializer = PacketSerializer()
        
        serializer.push(data: VideoTime(timingInfo).nsData())
        serializer.push(data: NSData(bytes: sps!, length: spsLength))
        serializer.push(data: NSData(bytes: pps!, length: ppsLength))
        serializer.push(data: NSData(bytes: dataPointer!, length: Int(totalLength)))

//        print("data \(serializer.data.count)")
        byterate.process(data: serializer.data as Data)
        next?.process(data: serializer.data)
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NetworkH264Deserializer
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class VideoH264Deserializer : DataProcessor {
    
    private let next: VideoOutputProtocol?
    
    init(_ next: VideoOutputProtocol?) {
        self.next = next
    }
        
    func process(data: NSData) {
        
        let d = PacketDeserializer(data)
        
        let h264Time = d.popData()
        let h264SPS  = d.popData()
        let h264PPS  = d.popData()
        let h264Data = d.popData()
        
        do {
            // format description
            
            var formatDescription: CMFormatDescription?
            
            let parameterSetPointers : [UnsafePointer<UInt8>] = [h264SPS.bytes.assumingMemoryBound(to: UInt8.self),
                                                                 h264PPS.bytes.assumingMemoryBound(to: UInt8.self)]
            let parameterSetSizes : [Int] = [h264SPS.length,
                                             h264PPS.length]
            
            try checkStatus(CMVideoFormatDescriptionCreateFromH264ParameterSets(allocator: kCFAllocatorDefault,
                                                                                parameterSetCount: 2,
                                                                                parameterSetPointers: parameterSetPointers,
                                                                                parameterSetSizes: parameterSetSizes,
                                                                                nalUnitHeaderLength: 4,
                                                                                formatDescriptionOut: &formatDescription),
                            "CMVideoFormatDescriptionCreateFromH264ParameterSets failed")
            
            // block buffer
            
            var blockBuffer: CMBlockBuffer?
            let blockBufferData = UnsafeMutablePointer<Int8>.allocate(capacity: h264Data.length)
            blockBufferData.assign(from: h264Data.bytes.assumingMemoryBound(to: Int8.self), count: h264Data.length)
            
            try checkStatus(CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
                                                               memoryBlock: blockBufferData,
                                                               blockLength: h264Data.length,
                                                               blockAllocator: kCFAllocatorDefault,
                                                               customBlockSource: nil,
                                                               offsetToData: 0,
                                                               dataLength: h264Data.length,
                                                               flags: 0,
                                                               blockBufferOut: &blockBuffer), "createReadonlyBlockBuffer")
            
            // timing info
            
            var timingInfo = VideoTime(deserialize: h264Time).cmSampleTimingInfo
            
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
