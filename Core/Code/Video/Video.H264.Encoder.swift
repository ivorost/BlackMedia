
import AVFoundation
import VideoToolbox

fileprivate extension CMTimeValue {
    static let frameRate: CMTimeValue = 6
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Session
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class VideoEncoderSessionH264 : VideoSessionProtocol, VideoOutputProtocol {
    
    public typealias Callback = (VideoEncoderSessionH264) -> Void
    
    private var session: VTCompressionSession?
    private let inputDimension: CMVideoDimensions
    private var outputDimentions: CMVideoDimensions
    private let next: VideoOutputProtocol?

    init(inputDimension: CMVideoDimensions,
         outputDimentions: CMVideoDimensions,
         next: VideoOutputProtocol?) {
        self.inputDimension = inputDimension
        self.outputDimentions = outputDimentions
        self.next = next
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // IOSessionProtocol
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    func start() throws {
        print("start")
        
        let encoderSpecification: [NSString: AnyObject] = [:
            /*kVTCompressionPropertyKey_UsingHardwareAcceleratedVideoEncoder: kCFBooleanTrue,
            kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder: kCFBooleanTrue,
            kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder: kCFBooleanTrue*/ ]
        
        VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: Int32(outputDimentions.width / 1),
            height: Int32(outputDimentions.height / 1),
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: encoderSpecification as CFDictionary,
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

    func process(video: VideoBuffer) {
        _process(video: video)
    }
    
    func _process(video: VideoBuffer) {
        guard let session = self.session else { logError("VideoEncoderSessionH264 no session"); return }
        
        guard let imageBuffer:CVImageBuffer = CMSampleBufferGetImageBuffer(video.sampleBuffer) else { return }
        var flags:VTEncodeInfoFlags = VTEncodeInfoFlags()
        let videoRef = StructContainer(video)
                
        VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: imageBuffer,
            presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(video.sampleBuffer),
            duration: CMTime.video(fps: .frameRate),
            frameProperties: nil,
            sourceFrameRefcon: UnsafeMutableRawPointer(mutating: bridgeRetained(obj: videoRef)),
            infoFlagsOut: &flags)
    }
    
    private var sessionCallback: VTCompressionOutputCallback = {(
        outputCallbackRefCon:UnsafeMutableRawPointer?,
        sourceFrameRefCon:UnsafeMutableRawPointer?,
        status:OSStatus,
        infoFlags:VTEncodeInfoFlags,
        sampleBuffer_:CMSampleBuffer?
        ) in

        let SELF: VideoEncoderSessionH264 = unsafeBitCast(outputCallbackRefCon,
                                                          to: VideoEncoderSessionH264.self)
        let videoRef: StructContainer<VideoBuffer> = bridgeRetained(ptr: sourceFrameRefCon!)
        guard let sampleBuffer = sampleBuffer_ else { logError("VideoEncoderSessionH264 nil buffer"); return }
        
        if status != 0 {
            logAVError("VTCompressionSession to H264 failed")
            return
        }

        SELF.next?.process(video: VideoBuffer(ID: videoRef.inner.ID,
                                              buffer: sampleBuffer,
                                              orientation: videoRef.inner.orientation))
    } as VTCompressionOutputCallback
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Settings
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    let defaultAttributes:[NSString: AnyObject] = [
        kCVPixelBufferPixelFormatTypeKey: Int(Capture.shared.pixelFormat) as AnyObject ]
    
    fileprivate var attributes:[NSString: AnyObject] {
        var attributes:[NSString: AnyObject] = defaultAttributes
        attributes[kCVPixelBufferHeightKey] = inputDimension.height as AnyObject
        attributes[kCVPixelBufferWidthKey] = inputDimension.width as AnyObject
        return attributes
    }
    
    var profileLevel:String = kVTProfileLevel_H264_High_AutoLevel as String
    fileprivate var properties:[NSString: AnyObject] {
        let isBaseline:Bool = profileLevel.contains("Baseline")
        let bitrate = Int(outputDimentions.width * outputDimentions.height / 3)
        var properties = [NSString: AnyObject]()
        
        properties[kVTCompressionPropertyKey_RealTime] = kCFBooleanTrue
        properties[kVTCompressionPropertyKey_ProfileLevel] = profileLevel as NSObject
        properties[kVTCompressionPropertyKey_AverageBitRate] = bitrate as NSObject
        properties[kVTCompressionPropertyKey_AllowFrameReordering] = kCFBooleanFalse
        properties[kVTCompressionPropertyKey_ExpectedFrameRate] = NSNumber(value: .frameRate)

        #if os(OSX)
        properties[kVTCompressionPropertyKey_MaxFrameDelayCount] = NSNumber(value: 1)
        properties[kVTCompressionPropertyKey_MaxKeyFrameInterval] = NSNumber(value: 0.0 as Double)
        properties[kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration] = NSNumber(value: 0.0 as Double)
        #endif

        var dataRateSupported = false

        #if os(OSX)
        dataRateSupported = true
        #else
        if #available(iOS 13.0, *) {
            dataRateSupported = true
        }
        #endif

        if dataRateSupported {
            let dataRate = [1024 * 1024, 1]
            properties[kVTCompressionPropertyKey_DataRateLimits] = dataRate as NSArray
        }

        var allowTemporalCompressionSupported = false
        
        #if os(OSX)
        allowTemporalCompressionSupported = true
        #else
        if #available(iOS 13.0, *) {} else {
            allowTemporalCompressionSupported = true
        }
        #endif

        if allowTemporalCompressionSupported {
            properties[kVTCompressionPropertyKey_AllowTemporalCompression] = kCFBooleanFalse
        }
        
        if (!isBaseline) {
            properties[kVTCompressionPropertyKey_H264EntropyMode] = kVTH264EntropyMode_CABAC
        }
        
        return properties
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Setup
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public class VideoSetupEncoder : VideoSetupSlave {
    private let settings: VideoEncoderConfig

    public init(root: VideoSetupProtocol, settings: VideoEncoderConfig) {
        self.settings = settings
        super.init(root: root)
    }
    
    public override func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        var result = video
        
        if kind == .capture {
            let serializerData = root.data(DataProcessor.shared, kind: .serializer)
            let serializer = VideoH264Serializer(next: serializerData)
            let serializerVideo = root.video(serializer, kind: .serializer)
            let encoder = VideoEncoderSessionH264(inputDimension: settings.input,
                                                  outputDimentions: settings.output,
                                                  next: serializerVideo)

            let encoderVideo = root.video(encoder, kind: .encoder)
            
            result = VideoProcessor(prev: result, next: encoderVideo)
            root.session(encoder, kind: .encoder)
        }
                
        return super.video(result, kind: kind)
    }
}
