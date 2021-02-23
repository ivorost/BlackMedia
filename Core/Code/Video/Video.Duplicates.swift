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


extension MTLTexture {
 
    func threadGroupCount() -> MTLSize {
        return MTLSizeMake(8, 8, 1)
    }
 
    func threadGroups() -> MTLSize {
        let groupCount = threadGroupCount()
        return MTLSizeMake(Int(self.width) / groupCount.width, Int(self.height) / groupCount.height, 1)
    }
}


public class VideoRemoveDuplicateFramesBase : VideoProcessor {
    private var lastImageBuffer: CVImageBuffer?
    private let lock = NSLock()
    fileprivate let duplicatesFree: VideoOutputProtocol

    required init(next: VideoOutputProtocol, duplicatesFree: VideoOutputProtocol) {
        self.duplicatesFree = duplicatesFree
        super.init(next: next)
    }

    fileprivate func isEqual(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) -> Bool? {
        return nil
    }
    
    public override func process(video: VideoBuffer) {
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


public class VideoRemoveDuplicateFramesUsingMetal : VideoRemoveDuplicateFramesBase {
    private var textureCache: CVMetalTextureCache?
    private var commandQueue: MTLCommandQueue?
    private var computePipelineState: MTLComputePipelineState?
    private let metalDevice = MTLCreateSystemDefaultDevice()
    private var context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)

    override func isEqual(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) -> Bool? {
        guard
            let computePipelineState = computePipelineState,
            let metalDevice = metalDevice,
            let commandQueue = commandQueue,
            let textureCache = textureCache
        else {
            return nil
        }
        
        do {
            // Converts the pixel buffer in a Metal texture.
            let inputTextures1 = try pixelBuffer1.cvMTLTexture(textureCache: textureCache)
            let inputTextures2 = try pixelBuffer2.cvMTLTexture(textureCache: textureCache)
            
            guard inputTextures1.count == inputTextures2.count else {
                assert(false); return nil
            }
            
            for i in 0 ..< inputTextures1.count {
                let inputTexture1 = inputTextures1[i]
                let inputTexture2 = inputTextures2[i]

                // Create a command buffer
                let commandBuffer = commandQueue.makeCommandBuffer()!
                
                // Create a compute command encoder.
                let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
                
                // Set the compute pipeline state for the command encoder.
                computeCommandEncoder.setComputePipelineState(computePipelineState)
                
                // Set the input and output textures for the compute shader.
                computeCommandEncoder.setTexture(inputTexture1, index: 0)
                computeCommandEncoder.setTexture(inputTexture2, index: 1)
                //        computeCommandEncoder.setTexture(inputTexture3, index: 2)
                
                var outBuffervalue = Int(0)
                let outBuffer = metalDevice.makeBuffer(bytes: &outBuffervalue, length: MemoryLayout<Int>.size, options: [])!
                computeCommandEncoder.setBuffer(outBuffer, offset: 0, index: 0)
                
                // Encode a threadgroup's execution of a compute function
                computeCommandEncoder.dispatchThreadgroups(inputTexture1.threadGroups(), threadsPerThreadgroup: inputTexture1.threadGroupCount())
                
                // End the encoding of the command.
                computeCommandEncoder.endEncoding()
                
                // Commit the command buffer for execution.
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
                
                // result
                
                let result = outBuffer.contents().bindMemory(to: Int.self, capacity: 1)
                let data = result[0]
                
                if data == 5 {
                    return false
                }
                
                if data == 3 {
                    return true
                }
            }
        }
        catch {
            logAVError(error)
        }
        
        return nil
    }
    
    required init(next: VideoOutputProtocol, duplicatesFree: VideoOutputProtocol) {
        do {
            if let metalDevice = metalDevice {
                // Create a command queue.
                self.commandQueue = metalDevice.makeCommandQueue()!
                
                let url = Bundle.this.url(forResource: "default", withExtension: "metallib")!
                let library = try metalDevice.makeLibrary(URL: url)
                
                // Create a function with a specific name.
                let function = library.makeFunction(name: "compareRGBA")!
                
                // Create a compute pipeline with the above function.
                self.computePipelineState = try metalDevice.makeComputePipelineState(function: function)
                
                // Initialize the cache to convert the pixel buffer into a Metal texture.
                var textCache: CVMetalTextureCache?
                if CVMetalTextureCacheCreate(kCFAllocatorDefault,
                                             nil,
                                             metalDevice,
                                             nil,
                                             &textCache) != kCVReturnSuccess {
                    fatalError("Unable to allocate texture cache.")
                }
                else {
                    self.textureCache = textCache
                }
            }
        }
        catch {
            logAVError(error)
        }

        super.init(next: next, duplicatesFree: duplicatesFree)
    }
}


public class VideoRemoveDuplicateFramesUsingMemcmp : VideoRemoveDuplicateFramesBase {
    
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


public class VideoSetupDuplicatesTemplate<T> : VideoSetupSlave where T : VideoRemoveDuplicateFramesBase {
    public override func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        var result = video
        
        if kind == .capture {
            let duplicatesFree = root.video(VideoProcessor(next: result), kind: .duplicatesFree)
            let duplicatesNext = root.video(VideoProcessor(), kind: .duplicatesNext)

            result = T(next: duplicatesNext, duplicatesFree: duplicatesFree)
        }
        
        return result
    }
}


public typealias VideoSetupDuplicatesMetal = VideoSetupDuplicatesTemplate <VideoRemoveDuplicateFramesUsingMetal>
public typealias VideoSetupDuplicatesMemcmp = VideoSetupDuplicatesTemplate <VideoRemoveDuplicateFramesUsingMemcmp>

