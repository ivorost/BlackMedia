//
//  CoreTests.swift
//  CoreTests
//
//  Created by Ivan Kh on 10.02.2023.
//

import XCTest
import CoreVideo
import Core

extension NSImage {
    func pixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        context?.translateBy(x: 0, y: size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        let nsctxt = NSGraphicsContext(cgContext: context!, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsctxt
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        NSGraphicsContext.restoreGraphicsState()

        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }}


final class CoreTests: XCTestCase {
    private var processor: Video.RemoveDuplicatesApproxUsingMetal!
    private var pixelBuffer1: CVPixelBuffer!
    private var pixelBuffer2: CVPixelBuffer!

    override func setUpWithError() throws {
        let url1 = URL(fileURLWithPath: "/Users/ivankh/Downloads/camera/color/95.dng")
        let url2 = URL(fileURLWithPath: "/Users/ivankh/Downloads/camera/color/151.dng")
        let image1 = NSImage(contentsOf: url1)!
        let image2 = NSImage(contentsOf: url2)!
        let pixelBuffer1 = image1.pixelBuffer()!
        let pixelBuffer2 = image2.pixelBuffer()!
        let processor = Video.RemoveDuplicatesApproxUsingMetal(next: Video.Processor.shared,
                                                               duplicatesFree: Video.Processor.shared)
        self.processor = processor
        self.pixelBuffer1 = pixelBuffer1
        self.pixelBuffer2 = pixelBuffer2
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let diffData = processor.diffData(pixelBuffer1: pixelBuffer1, pixelBuffer2: pixelBuffer2)
        let diffMetal = processor.diffMetal(pixelBuffer1: pixelBuffer1, pixelBuffer2: pixelBuffer2)

//        XCTAssertEqual(diffMetal, 921600)
        XCTAssertEqual(diffData, diffMetal)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            _ = processor.diffMetal(pixelBuffer1: pixelBuffer1, pixelBuffer2: pixelBuffer2)
        }
    }
}
