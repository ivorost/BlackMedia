//
//  Video.Output.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 22.05.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif
import AVFoundation
import Accelerate

@available(iOSApplicationExtension, unavailable)
public extension Video {
    class Output : NSObject, Producer.Proto {
        
        public var next: Video.Processor.AnyProto?
        let inner: Capture.Output<AVCaptureVideoDataOutput>
        private let queue: DispatchQueue
        private var ID: UInt = 0
        private var processing = false

        public init(inner: Capture.Output<AVCaptureVideoDataOutput>,
                    queue: DispatchQueue = BlackMedia.Capture.queue,
                    next: Video.Processor.AnyProto = Video.Processor.shared) {

            self.inner = inner
            self.queue = queue
            self.next = next
            
            super.init()
        }
    }
}


@available(iOSApplicationExtension, unavailable)
extension Video.Output : Session.Proto {
    public func start() throws {
        logAVPrior("video input start")

        inner.output.setSampleBufferDelegate(self, queue: queue)
        try inner.start()
        #if canImport(UIKit)
        inner.output.updateOrientationFromInterface()
        #endif

        NotificationCenter.default.addObserver(
            forName: .AVSampleBufferDisplayLayerFailedToDecode,
            object: nil,
            queue: nil,
            using: failureNotification)
    }
    
    public func stop() {
        inner.output.setSampleBufferDelegate(nil, queue: nil)
        inner.stop()
    }
    
    private func failureNotification(notification: Notification) {
        logAVError("failureNotification " + notification.description)
    }
}

@available(iOSApplicationExtension, unavailable)
extension Video.Output : AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        guard !processing else { return }
        processing = true
        logAV("video input \(sampleBuffer.presentationSeconds)")
        
        let ID = self.ID
        self.ID += 1

        #if canImport(UIKit)
//        if let data = sampleBuffer.image()?.pngData() {
//            let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0] + "/samplebuffer"
//            let url = URL(fileURLWithPath: path)
//
//            if !FileManager.default.fileExists(atPath: url.path) {
//                try! FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true)
//            }
//
//            try! data.write(to: url.appendingPathComponent("\(ID).dng", conformingTo: .url))
//        }
        #endif

        self.next?.process(Video.Sample(ID: ID, buffer: sampleBuffer))
        processing = false
    }
}

public extension Capture.Output {
    static func video32BGRA(_ session: AVCaptureSession) -> Capture.Output<AVCaptureVideoDataOutput> {
        let result = AVCaptureVideoDataOutput()
        result.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        result.alwaysDiscardsLateVideoFrames = true
        return Capture.Output(output: result, session: session)
    }
}

extension CVPixelBuffer {
    func rawData() -> Data? {
        let bufferHeight = CVPixelBufferGetHeight(self);
//        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self);
        let size = bufferHeight * bytesPerRow ;

        guard let pixel = malloc(size) else { return nil }
//        let rowBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        CVPixelBufferLockBaseAddress(self, [])
        guard let rowBase = CVPixelBufferGetBaseAddress(self) else {
            CVPixelBufferUnlockBaseAddress(self, [])
            return nil
        }

        memcpy (pixel, rowBase, size);
        CVPixelBufferUnlockBaseAddress(self, [])

        return Data(bytes: pixel, count: size)
    }
}

#if canImport(UIKit)
import UIKit

extension CMSampleBuffer {
    func image(orientation: UIImage.Orientation = .up,
               scale: CGFloat = 1.0) -> UIImage? {
        if let buffer = CMSampleBufferGetImageBuffer(self) {
            let ciImage = CIImage(cvPixelBuffer: buffer)

            return UIImage(ciImage: ciImage,
                           scale: scale,
                           orientation: orientation)
        }

        return nil
    }

    func rawData() -> Data? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(self) else { return nil }
        return pixelBuffer.rawData()
    }

    func image2() -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(self) else {
          return nil
        }

        // pixel format is Bi-Planar Component Y'CbCr 8-bit 4:2:0, full-range (luma=[0,255] chroma=[1,255]).
        // baseAddr points to a big-endian CVPlanarPixelBufferInfo_YCbCrBiPlanar struct.
        //
        guard CVPixelBufferGetPixelFormatType(imageBuffer) == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange else {
            return nil
        }


        guard CVPixelBufferLockBaseAddress(imageBuffer, .readOnly) == kCVReturnSuccess else {
            return nil
        }

        defer {
            // be sure to unlock the base address before returning
            CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        }

        // 1st plane is luminance, 2nd plane is chrominance
        guard CVPixelBufferGetPlaneCount(imageBuffer) == 2 else {
            return nil
        }

        // 1st plane
        guard let lumaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0) else {
            return nil
        }

        let lumaWidth = CVPixelBufferGetWidthOfPlane(imageBuffer, 0)
        let lumaHeight = CVPixelBufferGetHeightOfPlane(imageBuffer, 0)
        let lumaBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0)
        var lumaBuffer = vImage_Buffer(
            data: lumaBaseAddress,
            height: vImagePixelCount(lumaHeight),
            width: vImagePixelCount(lumaWidth),
            rowBytes: lumaBytesPerRow
        )

        // 2nd plane
        guard let chromaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1) else {
            return nil
        }

        let chromaWidth = CVPixelBufferGetWidthOfPlane(imageBuffer, 1)
        let chromaHeight = CVPixelBufferGetHeightOfPlane(imageBuffer, 1)
        let chromaBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1)
        var chromaBuffer = vImage_Buffer(
            data: chromaBaseAddress,
            height: 0,//vImagePixelCount(chromaHeight),
            width: 0,//vImagePixelCount(chromaWidth),
            rowBytes: 0//chromaBytesPerRow
        )

        var argbBuffer = vImage_Buffer()

        defer {
            // we are responsible for freeing the buffer data
            free(argbBuffer.data)
        }

        // initialize the empty buffer
        guard vImageBuffer_Init(
            &argbBuffer,
            lumaBuffer.height,
            lumaBuffer.width,
            32,
            vImage_Flags(kvImageNoFlags)
            ) == kvImageNoError else {
                return nil
        }

        // full range 8-bit, clamped to full range, is necessary for correct color reproduction
        var pixelRange = vImage_YpCbCrPixelRange(
            Yp_bias: 0,
            CbCr_bias: 128,
            YpRangeMax: 255,
            CbCrRangeMax: 255,
            YpMax: 255,
            YpMin: 1,
            CbCrMax: 255,
            CbCrMin: 0
        )

        var conversionInfo = vImage_YpCbCrToARGB()

        // initialize the conversion info
        guard vImageConvert_YpCbCrToARGB_GenerateConversion(
            kvImage_YpCbCrToARGBMatrix_ITU_R_601_4, // Y'CbCr-to-RGB conversion matrix for ITU Recommendation BT.601-4.
            &pixelRange,
            &conversionInfo,
            kvImage420Yp8_CbCr8, // converting from
            kvImageARGB8888, // converting to
            vImage_Flags(kvImageNoFlags)
            ) == kvImageNoError else {
                return nil
        }

        // do the conversion
        guard vImageConvert_420Yp8_CbCr8ToARGB8888(
            &lumaBuffer, // in
            &chromaBuffer, // in
            &argbBuffer, // out
            &conversionInfo,
            nil,
            255,
            vImage_Flags(kvImageNoFlags)
            ) == kvImageNoError else {
                return nil
        }

        // core foundation objects are automatically memory mananged. no need to call CGContextRelease() or CGColorSpaceRelease()
        guard let context = CGContext(
            data: argbBuffer.data,
            width: Int(argbBuffer.width),
            height: Int(argbBuffer.height),
            bitsPerComponent: 8,
            bytesPerRow: argbBuffer.rowBytes,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
            ) else {
                return nil
        }

        guard let cgImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
#endif
