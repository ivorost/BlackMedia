
import AVFoundation

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NetworkH264Serializer
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class VideoH264Serializer : VideoOutputProtocol {
    
    private var qid: String = ""
    private var next: VideoOutputProtocol?
    private var history = [String]()
    private var previous: Data?
    private var byterate = Byterate(print: true)
    
    init(next: VideoOutputProtocol?) {
        self.next = next
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // IOQoSProtocol
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    func change(_ toQID: String, _ diff: Int) {
        self.qid = toQID
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // VideoOutputProtocol
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    func process(video: CMSampleBuffer) {
        do {
            let formatDescription: CMFormatDescription = CMSampleBufferGetFormatDescription(video)!
            
            assert(CMSampleBufferGetNumSamples(video) == 1)
            
            // timing info
            
            var timingInfo = CMSampleTimingInfo()
            
            if CMSampleBufferGetSampleTimingInfo(video,
                                                 at: 0,
                                                 timingInfoOut: &timingInfo) != 0 {
//                "CMSampleBufferGetSampleTimingInfo failed"
                assert(false);
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
//                "An Error occured while getting h264 sps parameter"
                assert(false)
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
//                "An Error occured while getting h264 pps parameter")
                assert(false)
            }
            
            assert(count == 2) // sps and pps
            
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
                //"CMBlockBufferGetDataPointer failed"
                assert(false)
            }
            
            assert(length == totalLength)
            
            // build data
            
            var data = Data()
            
            data.append(NSData(bytes: sps!, length: spsLength) as Data)
            data.append(NSData(bytes: pps!, length: ppsLength) as Data)
            data.append(NSData(bytes: dataPointer!, length: Int(totalLength)) as Data)
            
//            history.append(data.base64EncodedString())
            print("data \(data.count)")
            byterate.process(data: data)

            // output

            previous = data
            next?.process(video: video)
        }
        catch {
            logError(error)
        }
    }
}
