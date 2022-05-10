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
    class RemoveDuplicateFramesBase : Video.Processor.Base {
        private var lastImageBuffer: CVImageBuffer?
        private let lock = NSLock()
        fileprivate let duplicatesFree: Video.Processor.Proto

        required init(next: Video.Processor.Proto, duplicatesFree: Video.Processor.Proto) {
            self.duplicatesFree = duplicatesFree
            super.init(next: next)
        }

        fileprivate func isEqual(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) -> Bool? {
            return nil
        }
        
        public override func process(video: Video.Buffer) {
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
                duplicatesFree.process(video: video)
            }

            super.process(video: duplicate ? video.copy(flags: [.duplicate]) : video)
        }
    }
}


public extension Video {
    class RemoveDuplicateFramesUsingMetal : Video.RemoveDuplicateFramesBase {
        private let metalProcessor: MetalProcessor.PixelBuffer?
        
        required init(next: Video.Processor.Proto, duplicatesFree: Video.Processor.Proto) {
            do {
                let url = Bundle.this.url(forResource: "default", withExtension: "metallib")!
                metalProcessor = try MetalProcessor.PixelBuffer(library: url, function: "compareRGBA")
            }
            catch {
                metalProcessor = nil
                logAVError(error)
            }
            
            super.init(next: next, duplicatesFree: duplicatesFree)
        }
        
        override func isEqual(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) -> Bool? {
            do {
                var outBufferValue = Int(0)
                var outBuffer: MTLBuffer?
                var result: Bool?
                
                let initialize = { (computeCommandEncoder: MTLComputeCommandEncoder) -> Void in
                    outBuffer = self.metalProcessor?.metalDevice.makeBuffer(bytes: &outBufferValue,
                                                                            length: MemoryLayout<Int>.size,
                                                                            options: [])!
                    computeCommandEncoder.setBuffer(outBuffer, offset: 0, index: 0)
                }
                
                let complete = { (computeCommandEncoder: MTLComputeCommandEncoder) -> Void in
                    guard let outBuffer = outBuffer else { assert(false); return }
                    let resultPointer = outBuffer.contents().bindMemory(to: Int.self, capacity: 1)
                    let data = resultPointer[0]
                    
                    if data == 5 {
                        result = false
                    }
                    
                    if data == 3 {
                        result = true
                    }
                }
                
                try metalProcessor?.processAndWait(pixelBuffer1: pixelBuffer1,
                                                   pixelBuffer2: pixelBuffer2,
                                                   initialize: initialize,
                                                   complete: complete)
                
                return result
            }
            catch {
                logAVError(error)
            }
            
            return nil
        }
    }
}


public extension Video {
    class RemoveDuplicateFramesUsingMemcmp : Video.RemoveDuplicateFramesBase {
        
        override func isEqual(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) -> Bool? {
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
        public override func video(_ video: Video.Processor.Proto, kind: Video.Processor.Kind) -> Video.Processor.Proto {
            var result = video
            
            if kind == .capture {
                let duplicatesFree = root.video(Video.Processor.Base(next: result), kind: .duplicatesFree)
                let duplicatesNext = root.video(Video.Processor.shared, kind: .duplicatesNext)
                
                result = T(next: duplicatesNext, duplicatesFree: duplicatesFree)
            }
            
            return result
        }
    }
}


public extension Video.Setup {
    typealias DuplicatesMetal = DuplicatesTemplate <Video.RemoveDuplicateFramesUsingMetal>
    typealias DuplicatesMemcmp = DuplicatesTemplate <Video.RemoveDuplicateFramesUsingMemcmp>
}
