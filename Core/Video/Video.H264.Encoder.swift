
import AVFoundation
import VideoToolbox

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Session
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class VideoEncoderSessionH264 : VideoSessionProtocol, VideoOutputProtocol {
    
    public typealias Callback = (VideoEncoderSessionH264) -> Void
    
    private var session: VTCompressionSession?
    private let inputDimension: CMVideoDimensions
    private var outputDimentions: CMVideoDimensions
    private let next: VideoOutputProtocol?
    private let callback: Callback?

    init(inputDimension: CMVideoDimensions,
         outputDimentions: CMVideoDimensions,
         next: VideoOutputProtocol?) {
        self.inputDimension = inputDimension
        self.outputDimentions = outputDimentions
        self.next = next
        self.callback = nil
    }

    init(inputDimension: CMVideoDimensions,
         outputDimentions: CMVideoDimensions,
         next: VideoOutputProtocol?,
         callback: @escaping Callback) {
        self.inputDimension = inputDimension
        self.outputDimentions = outputDimentions
        self.next = next
        self.callback = callback
    }
    
    private var sessionCallback: VTCompressionOutputCallback = {(
        outputCallbackRefCon:UnsafeMutableRawPointer?,
        sourceFrameRefCon:UnsafeMutableRawPointer?,
        status:OSStatus,
        infoFlags:VTEncodeInfoFlags,
        sampleBuffer_:CMSampleBuffer?
        ) in
        
        let SELF: VideoEncoderSessionH264 = unsafeBitCast(outputCallbackRefCon, to: VideoEncoderSessionH264.self)
        guard let sampleBuffer = sampleBuffer_ else { logError("VideoEncoderSessionH264 nil buffer"); return }
        
        if status != 0 {
            logAVError("VTCompressionSession to H264 failed")
            return
        }
        
        Capture.shared.captureQueue.async {
            SELF.callback?(SELF)
            SELF.next?.process(video: sampleBuffer)
        }
        
        } as VTCompressionOutputCallback

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // IOSessionProtocol
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    func start() throws {
        VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: Int32(outputDimentions.width),
            height: Int32(outputDimentions.height),
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: attributes as CFDictionary,
            compressedDataAllocator: nil,
            outputCallback: sessionCallback,
            refcon: unsafeBitCast(self, to: UnsafeMutableRawPointer.self),
            compressionSessionOut: &session)
        
        assert(session != nil)
        
        VTSessionSetProperties(session!, propertyDictionary: properties as CFDictionary)
        VTCompressionSessionPrepareToEncodeFrames(session!)
    }

    func stop() {        
        guard let session = self.session else { return }
        
        VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: CMTime.invalid)
        VTCompressionSessionInvalidate(session)
        
        self.session = nil
    }
    
    func update(_ outputFormat: VideoConfig) throws {
        assert(false)
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // VideoOutputProtocol
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    func process(video: CMSampleBuffer) {
        guard let imageBuffer:CVImageBuffer = CMSampleBufferGetImageBuffer(video) else { return }
        guard let session = self.session else { logError("VideoEncoderSessionH264 no session"); return }
        var flags:VTEncodeInfoFlags = VTEncodeInfoFlags()
        
        VTCompressionSessionEncodeFrame(session,
                                        imageBuffer: imageBuffer,
                                        presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(video),
                                        duration: CMSampleBufferGetDuration(video),
                                        frameProperties: nil,
                                        sourceFrameRefcon: nil,
                                        infoFlagsOut: &flags)
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Settings
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //kCVPixelFormatType_32BGRA
    
    let defaultAttributes:[NSString: AnyObject] = [
        kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA) as AnyObject,
        ]
    fileprivate var width:Int32!
    fileprivate var height:Int32!
    
    fileprivate var attributes:[NSString: AnyObject] {
        var attributes:[NSString: AnyObject] = defaultAttributes
        attributes[kCVPixelBufferHeightKey] = inputDimension.height as AnyObject
        attributes[kCVPixelBufferWidthKey] = inputDimension.width as AnyObject
        return attributes
    }
    
    var profileLevel:String = kVTProfileLevel_H264_Baseline_AutoLevel as String
    fileprivate var properties:[NSString: AnyObject] {
        let isBaseline:Bool = profileLevel.contains("Baseline")
        var properties:[NSString: AnyObject] = [
            kVTCompressionPropertyKey_RealTime: kCFBooleanTrue,
            kVTCompressionPropertyKey_ProfileLevel: profileLevel as NSObject,
            kVTCompressionPropertyKey_AverageBitRate: Int(outputDimentions.width * outputDimentions.height) as NSObject,
            kVTCompressionPropertyKey_MaxKeyFrameInterval: NSNumber(value: 0.0 as Double),
            kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration: NSNumber(value: 0.0 as Double),
            kVTCompressionPropertyKey_AllowFrameReordering: !isBaseline as NSObject,
        ]
        if (!isBaseline) {
            properties[kVTCompressionPropertyKey_H264EntropyMode] = kVTH264EntropyMode_CABAC
        }
        return properties
    }
}
