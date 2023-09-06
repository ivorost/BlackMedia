
import CoreMedia
import CoreImage

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

extension CMVideoDimensions : Equatable {
    
    public static func ==(lhs: CMVideoDimensions, rhs: CMVideoDimensions) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }

    public var size: CGSize {
        return CGSize(width: CGFloat(width), height: CGFloat(height))
    }

    public var bitrate: Int32 {
        return width * height
    }

    public func turn() -> CMVideoDimensions {
        return CMVideoDimensions(width: height, height: width)
    }
}

public extension CMSampleBuffer {
    
    var presentationSeconds: Double {
        return CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(self))
    }
    
    var videoDimentions: CMVideoDimensions? {
        let imageBuffer = CMSampleBufferGetImageBuffer(self)

        if let imageBuffer = imageBuffer, CFGetTypeID(imageBuffer) == CVPixelBufferGetTypeID() {
            var result = CMVideoDimensions()
            
            CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
            result.width = Int32(CVPixelBufferGetWidth(imageBuffer))
            result.height = Int32(CVPixelBufferGetHeight(imageBuffer))
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
            
            return result
        }
        else {
            return nil
        }
    }

    var videoSize: CGSize? {
        guard let dimentions = videoDimentions else { return nil }
        return CGSize(width: CGFloat(dimentions.width), height: CGFloat(dimentions.height))
    }

    var image: AppleImage? {
        guard let buffer = CMSampleBufferGetImageBuffer(self) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: buffer)
        
        return AppleImage(ciImage: ciImage)
    }

    var cgImage: CGImage? {
        guard
            let buffer = CMSampleBufferGetImageBuffer(self),
            let size = videoSize
        else { return nil }

        let ciImage = CIImage(cvPixelBuffer: buffer)
        let ciContext = CIContext()

        return ciContext.createCGImage(ciImage, from: CGRect(origin: .zero, size: size))
    }
}

public func CMTimeSetSeconds(_ time: inout CMTime, _ seconds: Float64) {
    time.value = CMTimeValue(seconds * Float64(time.timescale))
}


public extension CMTimeScale {
    static let prefferedVideoTimescale: CMTimeScale = 600
}

public extension CMTimeValue {
    static let prefferedVideoTimescale: CMTimeValue = CMTimeValue(CMTimeScale.prefferedVideoTimescale)
}


public extension CMTime {
    
    static func video(value: CMTimeValue) -> CMTime {
        return CMTime(value: value, timescale: .prefferedVideoTimescale)
    }

    static func video(fps: CMTimeValue) -> CMTime {
        return CMTime(value: .prefferedVideoTimescale / fps, timescale: .prefferedVideoTimescale)
    }
}

#if canImport(AppKit)
private extension NSImage {
    convenience init(ciImage: CIImage) {
        let rep: NSCIImageRep = NSCIImageRep(ciImage: ciImage)
        self.init(size: rep.size)
        addRepresentation(rep)
    }
}
#endif
