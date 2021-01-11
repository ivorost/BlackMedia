//
//  Video.Duplicates.swift
//  Capture
//
//  Created by Ivan Kh on 27.10.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation
import AppKit


extension MTLTexture {
 
    func threadGroupCount() -> MTLSize {
        return MTLSizeMake(8, 8, 1)
    }
 
    func threadGroups() -> MTLSize {
        let groupCount = threadGroupCount()
        return MTLSizeMake(Int(self.width) / groupCount.width, Int(self.height) / groupCount.height, 1)
    }
}


class VideoRemoveDuplicateFramesBase : VideoOutputWithNext {
    private var lastImageBuffer: CVImageBuffer?
    private var duplicatesCount = 0
    private let lock = NSLock()

    fileprivate func isEqual(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) -> Bool? {
        return nil
    }

    override func process(video: VideoBuffer) {
        var process = true
        
        lock.locked {
            let imageBuffer = CMSampleBufferGetImageBuffer(video.sampleBuffer)
            
            if process,
                let lastImageBuffer = lastImageBuffer,
                let imageBuffer = imageBuffer,
                isEqual(pixelBuffer1: lastImageBuffer, pixelBuffer2: imageBuffer) == true {
                process = false
            }
            
            if process {
                duplicatesCount = 0
            }
            else {
                duplicatesCount += 1
            }
            
            if duplicatesCount == 5 {
                process = true
                print("aaa")
            }
            
            lastImageBuffer = imageBuffer
        }

        if process {
            super.process(video: video)
        }
    }
}


class VideoRemoveDuplicateFramesUsingMetal : VideoRemoveDuplicateFramesBase {
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
                
//                print("number \(data)")
            }
        }
        catch {
            logAVError(error)
        }
        
        return nil
    }
    
    required init(next: VideoOutputProtocol? = nil) {
        do {
            if let metalDevice = metalDevice {
                // Create a command queue.
                self.commandQueue = metalDevice.makeCommandQueue()!
                
                let url = Bundle.main.url(forResource: "default", withExtension: "metallib")!
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

        super.init(next: next)
    }
}


class VideoRemoveDuplicateFramesUsingMemcmp : VideoRemoveDuplicateFramesBase {
    
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


class VideoSetupDuplicatesTemplate<T> : VideoSetupSlave where T : VideoOutputWithNextProtocol {
    override func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        var result = video
        
        if kind == .capture {
            let next = root.video(VideoProcessor(next: result), kind: .duplicatesFree)
            result = T(next: next)
            result = root.video(result, kind: .duplicates)
        }
        
        return result
    }
}


typealias VideoSetupDuplicatesMetal = VideoSetupDuplicatesTemplate <VideoRemoveDuplicateFramesUsingMetal>
typealias VideoSetupDuplicatesMemcmp = VideoSetupDuplicatesTemplate <VideoRemoveDuplicateFramesUsingMemcmp>

