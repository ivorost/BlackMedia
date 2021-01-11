
import CoreMedia

extension CMVideoDimensions : Equatable {
    
    public static func ==(lhs: CMVideoDimensions, rhs: CMVideoDimensions) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }

    var size: CGSize {
        return CGSize(width: CGFloat(width), height: CGFloat(height))
    }
    
    func turn() -> CMVideoDimensions {
        return CMVideoDimensions(width: height, height: width)
    }
    
    func bitrate() -> Int32 {
        return width * height
    }
    
}

extension CMSampleBuffer {
    
    var presentationSeconds: Double {
        return CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(self))
    }
}

func CMTimeSetSeconds(_ time: inout CMTime, _ seconds: Float64) {
    time.value = CMTimeValue(seconds * Float64(time.timescale))
}


extension CMTimeScale {
    static let prefferedVideoTimescale: CMTimeScale = 600
}

extension CMTimeValue {
    static let prefferedVideoTimescale: CMTimeValue = CMTimeValue(CMTimeScale.prefferedVideoTimescale)
}


extension CMTime {
    
    static func video(value: CMTimeValue) -> CMTime {
        return CMTime(value: value, timescale: .prefferedVideoTimescale)
    }

    static func video(fps: CMTimeValue) -> CMTime {
        return CMTime(value: .prefferedVideoTimescale / fps, timescale: .prefferedVideoTimescale)
    }
}
