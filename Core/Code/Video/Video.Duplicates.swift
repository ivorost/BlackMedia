//
//  Video.Duplicates.swift
//  Capture
//
//  Created by Ivan Kh on 27.10.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation
import CoreVideo
import CoreImage


public extension Video {
    class RemoveDuplicateFramesBase : Video.Processor.Proto, Producer.Proto {

        public var next: Processor.AnyProto?
        private var lastImageBuffer: CVImageBuffer?
        private let lock = NSLock()

        required init() {
        }

        fileprivate func isEqual(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) -> Bool? {
            return nil
        }
        
        public func process(_ video: Video.Sample) {
            var duplicate = false
            
            lock.locked {
                let imageBuffer = CMSampleBufferGetImageBuffer(video.sampleBuffer)
                
                if let lastImageBuffer = lastImageBuffer,
                   let imageBuffer = imageBuffer,
                   isEqual(pixelBuffer1: lastImageBuffer, pixelBuffer2: imageBuffer) == true {
                    duplicate = true
                }
                
                lastImageBuffer = imageBuffer
            }

            if !duplicate {
                next?.process(video)
            }
        }
    }
}


public extension Video {
    class RemoveDuplicatesStrictUsingMetal : Video.RemoveDuplicateFramesBase {
        private let metalProcessor: MetalProcessor.TwoBitmaps?
        
        required override init() {
            do {
                let url = Bundle.this.url(forResource: "default", withExtension: "metallib")!
                metalProcessor = try MetalProcessor.TwoBitmaps(library: url,
                                                               function: "compareRGBAStrict",
                                                               buffer: .constant(value: 1))
            }
            catch {
                metalProcessor = nil
                logAVError(error)
            }
            
            super.init()
        }
        
        public override func isEqual(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) -> Bool? {
            guard let metalProcessor else { return nil }

            do {
                metalProcessor.buffer.fill(with: 0)
                try metalProcessor.processAndWait(pixelBuffer1: pixelBuffer1, pixelBuffer2: pixelBuffer2)

                if metalProcessor.buffer[0] == 3 {
                    return true
                }

                if metalProcessor.buffer[0] == 5 {
                    return false
                }

                return nil
            }
            catch {
                logAVError(error)
            }
            
            return nil
        }
    }
}


public extension Video {
    class RemoveDuplicatesApproxUsingMetal : Video.RemoveDuplicateFramesBase {
        private let metalProcessor: MetalProcessor.TwoBitmaps?

        public required init() {
            do {
                let url = Bundle.this.url(forResource: "default", withExtension: "metallib")!
                metalProcessor = try MetalProcessor.TwoBitmaps(library: url,
                                                               function: "compareRGBAApprox",
                                                               buffer: .threadExecutionWidth)
            }
            catch {
                metalProcessor = nil
                logAVError(error)
            }

            super.init()
        }

        public override func isEqual(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) -> Bool? {
            guard let metalProcessor else { return nil }

            do {
                metalProcessor.buffer.fill(with: 0)
                try metalProcessor.processAndWait(pixelBuffer1: pixelBuffer1, pixelBuffer2: pixelBuffer2)

                if metalProcessor.buffer[1] == 0 {
                    return false
                }

                if metalProcessor.buffer[2] / metalProcessor.buffer[1] > 8 {
                    return false
                }

                if metalProcessor.buffer[3] > 8 {
                    return false
                }

                return true
            }
            catch {
                logAVError(error)
            }

            return nil
        }

        public func diffMetal(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) -> Int? {
            guard let metalProcessor else { return nil }

            do {
                metalProcessor.buffer.fill(with: 0)
                try metalProcessor.processAndWait(pixelBuffer1: pixelBuffer1, pixelBuffer2: pixelBuffer2)

                return Int(metalProcessor.buffer[0])
            }
            catch {
                logAVError(error)
            }

            return nil
        }

        public func diffData(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) -> Int {
            guard let data1 = pixelBuffer1.rawData() else { return 0 }
            guard let data2 = pixelBuffer2.rawData() else { return 0 }
            var result = 0
            var index = 0

            let x1 = data1.prefix(20)
            let x2 = data2.prefix(20)

            print("\(x1) \(x2)")
            repeat {
                if data1[index] != data2[index] ||
                    data1[index+1] != data2[index+1] ||
                    data1[index+2] != data2[index+2] ||
                    data1[index+3] != data2[index+3] {
                    result += 1
                }

                index += 4
            }
            while index < data1.count

            return result
        }
    }
}


public extension Video {
    class RemoveDuplicatesStrictUsingMemcmp : Video.RemoveDuplicateFramesBase {
        
        public override func isEqual(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) -> Bool? {
            guard
                let surface1 = CVPixelBufferGetIOSurface(pixelBuffer1)?.takeUnretainedValue(),
                let surface2 = CVPixelBufferGetIOSurface(pixelBuffer2)?.takeUnretainedValue()
            else {
                return nil
            }
            
            CVPixelBufferLockBaseAddress(pixelBuffer1, [])
            CVPixelBufferLockBaseAddress(pixelBuffer2, [])
            IOSurfaceLock(surface1, [], nil)
            IOSurfaceLock(surface2, [], nil)
            
            let baseAddress1 = IOSurfaceGetBaseAddress(surface1)
            let baseAddress2 = IOSurfaceGetBaseAddress(surface2)
            let size1 = IOSurfaceGetAllocSize(surface1)
            let size2 = IOSurfaceGetAllocSize(surface2)
            
            let isEqual = (size1 == size2) && memcmp(baseAddress1, baseAddress2, size1) == 0
            
            IOSurfaceUnlock(surface1, [], nil)
            IOSurfaceUnlock(surface2, [], nil)
            CVPixelBufferUnlockBaseAddress(pixelBuffer1, [])
            CVPixelBufferUnlockBaseAddress(pixelBuffer2, [])
            
            return isEqual;
        }
    }
}

public extension Video.Setup {
    class DuplicatesTemplate<T> : Slave where T : Video.RemoveDuplicateFramesBase {
        public override func video(_ video: Video.Processor.AnyProto, kind: Video.Processor.Kind) -> Video.Processor.AnyProto {
            var result = video
            
            if kind == .capture {
                let duplicatesFree = root.video(Video.Processor.Base(next: result), kind: .duplicatesFree)
                let duplicatesNext = root.video(Video.Processor.shared, kind: .duplicatesNext)

                let concreteResult = T()
                concreteResult.next = duplicatesFree
                result = concreteResult
            }
            
            return result
        }
    }
}


public extension Video.Setup {
    typealias DuplicatesStrictMetal = DuplicatesTemplate <Video.RemoveDuplicatesStrictUsingMetal>
    typealias DuplicatesApproxMetal = DuplicatesTemplate <Video.RemoveDuplicatesApproxUsingMetal>
    typealias DuplicatesStrictMemcmp = DuplicatesTemplate <Video.RemoveDuplicatesStrictUsingMemcmp>
}
