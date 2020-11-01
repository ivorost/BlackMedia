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
        return MTLSizeMake(30, 30, 1)
    }
 
    func threadGroups() -> MTLSize {
        let groupCount = threadGroupCount()
        return MTLSizeMake(Int(self.width) / groupCount.width, Int(self.height) / groupCount.height, 1)
    }
}


class VideoRemoveDuplicateFrames : VideoOutputImpl {
    private var lastImageBuffer: CVImageBuffer?
    private var textureCache: CVMetalTextureCache?
    private var commandQueue: MTLCommandQueue?
    private var computePipelineState: MTLComputePipelineState?
    private let metalDevice = MTLCreateSystemDefaultDevice()
    private var context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)

    func compare(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) -> Bool? {
        guard
            let computePipelineState = computePipelineState,
            let metalDevice = metalDevice,
            let commandQueue = commandQueue
        else {
            return nil
        }
        
        // Get width and height for the pixel buffer
        let width = CVPixelBufferGetWidth(pixelBuffer1)
        let height = CVPixelBufferGetHeight(pixelBuffer1)
        
        // Converts the pixel buffer in a Metal texture.
        var cvTexture1: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer1, nil, .bgra8Unorm, width, height, 0, &cvTexture1)
        guard let cvTexture11 = cvTexture1, let inputTexture1 = CVMetalTextureGetTexture(cvTexture11) else {
            assert(false)
            return nil
        }

        var cvTexture2: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer2, nil, .bgra8Unorm, width, height, 0, &cvTexture2)
        guard let cvTexture22 = cvTexture2, let inputTexture2 = CVMetalTextureGetTexture(cvTexture22) else {
            assert(false)
            return nil
        }

//        var cvTexture3: CVMetalTexture?
//        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.textureCache!, pixelBuffer2, nil, .bgra8Unorm, width, height, 0, &cvTexture3)
//        guard let cvTexture33 = cvTexture3, let inputTexture3 = CVMetalTextureGetTexture(cvTexture33) else {
//            assert(false)
//            return nil
//        }

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

//        var test1 = Float(0)
//        computeCommandEncoder.setBytes(&test1, length: MemoryLayout<Float>.size, index: 1)
//
//        var test2 = Float(0)
//        computeCommandEncoder.setBytes(&test2, length: MemoryLayout<Float>.size, index: 2)
        
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
                
        return nil
    }
    
    override init(next: VideoOutputProtocol? = nil, measure: MeasureProtocol? = nil) {
        do {
            if let metalDevice = metalDevice {
                // Create a command queue.
                self.commandQueue = metalDevice.makeCommandQueue()!
                
                let url = Bundle.main.url(forResource: "default", withExtension: "metallib")!
                let library = try metalDevice.makeLibrary(URL: url)
                
                // Create a function with a specific name.
                let function = library.makeFunction(name: "compare")!
                
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

        super.init(next: next, measure: measure)
    }
    
    override func processSelf(video: CMSampleBuffer) -> Bool {
        let imageBuffer = CMSampleBufferGetImageBuffer(video)
        var process = true

        if process && lastImageBuffer == imageBuffer {
            process = false
        }

        if process,
            let lastImageBuffer = lastImageBuffer,
            let imageBuffer = imageBuffer,
            compare(pixelBuffer1: lastImageBuffer, pixelBuffer2: imageBuffer) == true {
            process = false
        }
        
        lastImageBuffer = imageBuffer
        
        return process
    }
}
