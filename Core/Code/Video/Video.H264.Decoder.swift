
import Foundation
import CoreMedia
import VideoToolbox

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// VideoDecoderH264
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

public extension Video.Processor {
    class DecoderH264 : ProcessorProtocol, Session.Proto {
        
        private let next: Video.Processor.AnyProto?
        private var session: VTDecompressionSession?
        
        init(_ next: Video.Processor.AnyProto?) {
            self.next = next
        }
        
        public func start() throws {
        }
        
        public func stop() {
            
        }
        
        public func process(_ video: Video.Sample) {
            if session == nil {
                do {
                    guard
                        let formatDescription = CMSampleBufferGetFormatDescription(video.sampleBuffer)
                        else { logError("CMSampleBufferGetFormatDescription"); return }

                    let destinationPixelBufferAttributes = NSMutableDictionary()
                    destinationPixelBufferAttributes.setValue(NSNumber(value: Video.defaultPixelFormat),
                                                              forKey: kCVPixelBufferPixelFormatTypeKey as String)

                    let decoderSpecification = NSMutableDictionary()
                    #if os(OSX)
                    decoderSpecification[kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder]
                        = kCFBooleanTrue
                    #endif
                    
                    var outputCallback = VTDecompressionOutputCallbackRecord()
                    outputCallback.decompressionOutputCallback = callback
                    outputCallback.decompressionOutputRefCon = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
                    
                    try check(status: VTDecompressionSessionCreate(
                                allocator: kCFAllocatorDefault,
                                formatDescription: formatDescription,
                                decoderSpecification: decoderSpecification,
                                imageBufferAttributes: destinationPixelBufferAttributes,
                                outputCallback: &outputCallback,
                                decompressionSessionOut: &session),
                              message: "VTDecompressionSessionCreate")
                    
//                    var value: CFBoolean?
//
//                    VTSessionCopyProperty(session!, key: kVTDecompressionPropertyKey_UsingHardwareAcceleratedVideoDecoder, allocator: nil, valueOut: &value)
                }
                catch {
                    logAVError(error)
                }
            }
            
            var infoFlags = VTDecodeInfoFlags(rawValue: 0)
            let videoRef = StructContainer(video)

            VTDecompressionSessionDecodeFrame(session!,
                                              sampleBuffer: video.sampleBuffer,
                                              flags: [._1xRealTimePlayback],
                                              frameRefcon: UnsafeMutableRawPointer(mutating: bridgeRetained(obj: videoRef)),
                                              infoFlagsOut: &infoFlags)
            VTDecompressionSessionFinishDelayedFrames(session!)
            VTDecompressionSessionWaitForAsynchronousFrames(session!)
        }
        
        private var callback: VTDecompressionOutputCallback = {(decompressionOutputRefCon: UnsafeMutableRawPointer?,
            sourceFrameRefCon: UnsafeMutableRawPointer?,
            status: OSStatus,
            infoFlags: VTDecodeInfoFlags,
            imageBuffer: CVImageBuffer?,
            presentationTimeStamp: CMTime,
            presentationDuration: CMTime) in
            
            do {
                try check(status: status, message: "VTDecompressionOutputCallbacks")
                
                let SELF: DecoderH264 = unsafeBitCast(decompressionOutputRefCon, to: DecoderH264.self)
                let videoRef: StructContainer<Video.Sample> = bridgeRetained(ptr: sourceFrameRefCon!)
                var sampleBuffer: CMSampleBuffer?
                
                var sampleTiming = CMSampleTimingInfo(
                    duration: presentationDuration,
                    presentationTimeStamp: presentationTimeStamp,
                    decodeTimeStamp: .invalid
                )
                
                var formatDescription: CMFormatDescription?
                
                try check(status: CMVideoFormatDescriptionCreateForImageBuffer(
                            allocator: kCFAllocatorDefault,
                            imageBuffer: imageBuffer!,
                            formatDescriptionOut: &formatDescription),
                          message: "CMVideoFormatDescriptionCreateForImageBuffer")
                
                
                try check(status: CMSampleBufferCreateForImageBuffer(
                            allocator: kCFAllocatorDefault,
                            imageBuffer: imageBuffer!,
                            dataReady: true,
                            makeDataReadyCallback: nil,
                            refcon: nil,
                            formatDescription: formatDescription!,
                            sampleTiming: &sampleTiming,
                            sampleBufferOut: &sampleBuffer),
                          message: "CMSampleBufferCreateForImageBuffer")
                
                Video.decoderQueue.async {
                    SELF.next?.process(Video.Sample(ID: videoRef.inner.ID, buffer: sampleBuffer!))
                }
            }
            catch {
                logAVError(error)
            }
        } as VTDecompressionOutputCallback
    }
}


public extension Video.Setup {
    class DecoderH264 : Video.Setup.Slave {
        private let target: Video.Processor.Kind
        
        public init(root: Video.Setup.Proto, target: Video.Processor.Kind = .deserializer) {
            self.target = target
            super.init(root: root)
        }
        
        public override func video(_ video: Video.Processor.AnyProto, kind: Video.Processor.Kind) -> Video.Processor.AnyProto {
            var result = video
            
            if kind == self.target {
                let next = root.video(Video.Processor.shared, kind: .decoder)
                let decoder = Video.Processor.DecoderH264(next)
                
                result = Video.Processor.Base(prev: result, next: decoder)
            }
            
            return super.video(result, kind: kind)
        }
    }
}
