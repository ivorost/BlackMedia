//
//  AVFoundation.CaptureDevice.swift
//  Core
//
//  Created by Ivan Kh on 20.04.2022.
//

import Foundation
import AVFoundation
import BlackUtils


extension AVCaptureDevice {
    static var nannyCamera: AVCaptureDevice? {
        if let device = rearCamera {
            return device
        }
        
        if let device = frontCamera {
            return device
        }
        
        return unspecifiedCamera
    }
    
    var nannyFormat: Format {
        return formats.highDimensionOrdered.lowRateOrdered[0]
    }
}


public extension AVCaptureDeviceInput {
    enum Error : Swift.Error {
        case cameraRequired
    }

    private static func input(_ device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
        guard let device else {
            logError(Error.cameraRequired)
            return nil
        }

        do {
            return try AVCaptureDeviceInput(device: device)
        }
        catch {
            logError(error)
        }

        return nil
    }

    static var frontCamera: AVCaptureDeviceInput? {
        input(AVCaptureDevice.frontCamera)
    }

    static var rearCamera: AVCaptureDeviceInput? {
        input(AVCaptureDevice.rearCamera)
    }

    static var nannyCamera: AVCaptureDeviceInput? {
        input(AVCaptureDevice.nannyCamera)
    }
}


fileprivate extension Array where Element : AVFrameRateRange {
    var nannyOrdered: Self {
        return maxFrameRateOrdered.minFrameRateOrdered
    }
    
    var minFrameRateOrdered: Self {
        return sorted { first, second in
            first.minFrameRate < second.minFrameRate
        }
    }

    var maxFrameRateOrdered: Self {
        return sorted { first, second in
            first.maxFrameRate > second.maxFrameRate
        }
    }
}


fileprivate extension Array where Element : AVCaptureDevice.Format {
    var lowRateOrdered: Self {
        return sorted(by: lowRateComparator)
    }
    
    var highDimensionOrdered: Self {
        return sorted(by: highDimensionComparator)
    }
    
    func lowRateComparator(first: Element, second: Element) -> Bool {
        guard let firstRate = first.videoSupportedFrameRateRanges.nannyOrdered.first
        else { return false }
        
        guard let secondRate = second.videoSupportedFrameRateRanges.nannyOrdered.first
        else { return true }

        return firstRate.minFrameDuration < secondRate.minFrameDuration
    }

    func highDimensionComparator(first: Element, second: Element) -> Bool {
        return first.dimensions.bitrate > second.dimensions.bitrate
    }
}
