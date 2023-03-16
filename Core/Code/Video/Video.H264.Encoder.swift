
import AVFoundation
import VideoToolbox
import CoreVideo

fileprivate extension CMTimeValue {
    static let frameRate: CMTimeValue = 6
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Session
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public extension Video.Processor {
    class EncoderH264: Video.Producer.Proto {
        
        public typealias Callback = (EncoderH264) -> Void
        
        public var next: Video.Processor.AnyProto?
        private var session: VTCompressionSession?
        private let inputDimension: CMVideoDimensions
        private var outputDimentions: CMVideoDimensions
        private var rotated = false
        
        init(inputDimension: CMVideoDimensions,
             outputDimentions: CMVideoDimensions,
             next: Video.Processor.AnyProto? = Video.Processor.shared) {
            self.inputDimension = inputDimension
            self.outputDimentions = outputDimentions
            self.next = next
        }
        
        private func _process(video: Video.Sample) {
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
            
            let SELF: EncoderH264 = unsafeBitCast(outputCallbackRefCon, to: EncoderH264.self)
            let videoRef: StructContainer<Video.Sample> = bridgeRetained(ptr: sourceFrameRefCon!)
            guard let sampleBuffer = sampleBuffer_ else { logError("VideoEncoderSessionH264 nil buffer"); return }
            
            if status != 0 {
                logAVError("VTCompressionSession to H264 failed")
                return
            }
            
            SELF.next?.process(Video.Sample(ID: videoRef.inner.ID,
                                            buffer: sampleBuffer,
                                            orientation: videoRef.inner.orientation))
        } as VTCompressionOutputCallback
        
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Settings
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        private let defaultAttributes:[NSString: AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey: Int(Video.defaultPixelFormat) as AnyObject ]
        
        private var attributes:[NSString: AnyObject] {
            var attributes:[NSString: AnyObject] = defaultAttributes
            attributes[kCVPixelBufferHeightKey] = inputDimension.height as AnyObject
            attributes[kCVPixelBufferWidthKey] = inputDimension.width as AnyObject
            return attributes
        }
        
        private var profileLevel:String = kVTProfileLevel_H264_High_AutoLevel as String
        private var properties:[NSString: AnyObject] {
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
}


extension Video.Processor.EncoderH264 : ProcessorProtocol {
    public func process(_ video: Video.Sample) {
        if let rotated = isRotated(relative: video.sampleBuffer), rotated != self.rotated {
            self.rotated = rotated
            try? restart()
        }
        
        _process(video: video)
    }
}


extension Video.Processor.EncoderH264 : Session.Proto {
    public func start() throws {
        let encoderSpecification: [NSString: AnyObject] = [:
            /*kVTCompressionPropertyKey_UsingHardwareAcceleratedVideoEncoder: kCFBooleanTrue,
             kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder: kCFBooleanTrue,
             kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder: kCFBooleanTrue*/ ]
        var outputDimentions = self.outputDimentions
        
        if rotated {
            outputDimentions = outputDimentions.turn()
        }
        
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
    
    public func stop() {
        guard let session = self.session else { return }
        
        VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: CMTime.invalid)
        VTCompressionSessionInvalidate(session)
        
        self.session = nil
    }
}

// Utils
extension Video.Processor.EncoderH264 {
    private func isRotated(relative to: CMSampleBuffer) -> Bool? {
        guard let videoDimensions = to.videoDimentions else { return nil }
                
        if CGFloat(videoDimensions.width) / CGFloat(videoDimensions.height) < 1 &&
            CGFloat(outputDimentions.width) / CGFloat(outputDimentions.height) > 1 {
            return true
        }

        if CGFloat(videoDimensions.width) / CGFloat(videoDimensions.height) > 1 &&
            CGFloat(outputDimentions.width) / CGFloat(outputDimentions.height) < 1 {
            return true
        }

        return false
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Setup
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public extension Video.Setup {
    class EncoderH264 : Video.Setup.Slave {
        private let settings: Video.EncoderConfig

        public init(root: Video.Setup.Proto, settings: Video.EncoderConfig) {
            self.settings = settings
            super.init(root: root)
        }

        public override func video(_ video: Video.Processor.AnyProto, kind: Video.Processor.Kind) -> Video.Processor.AnyProto {
            var result = video
            
            if kind == .capture {
                let next = root.video(result, kind: .encoder)
                let encoder = Video.Processor.EncoderH264(inputDimension: settings.input,
                                                          outputDimentions: settings.output,
                                                          next: next)

                result = Video.Processor.Base(prev: result, next: encoder)
                root.session(encoder, kind: .encoder)
            }
            
            return super.video(result, kind: kind)
        }
    }
}
