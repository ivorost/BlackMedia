//
//  Video.Recolor.swift
//  Capture
//
//  Created by Ivan Kh on 19.01.2021.
//  Copyright © 2021 Ivan Kh. All rights reserved.
//

import AVFoundation
import CoreVideo
import CoreImage

// For convertion from sample.comp.hlsl to sample.comp.metal use:
// glslangValidator -e main -o sample.comp.spv -H -V -D sample.comp.hlsl
// spirv-cross sample.comp.spv --output sample.comp.metal --msl

public extension VideoProcessor {
    class Recolor : Base {
        private let lock = NSLock()
        private var textureCache: CVMetalTextureCache?
        private var commandQueue: MTLCommandQueue?
        private var computePipelineState: MTLComputePipelineState?
        private let metalDevice = MTLCreateSystemDefaultDevice()
        private var context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)

        public required init(next: VideoOutputProtocol) {
            do {
                if let metalDevice = metalDevice {
                    // Create a command queue.
                    self.commandQueue = metalDevice.makeCommandQueue()!
                    
                    let url = Bundle.main.url(forResource: "default", withExtension: "metallib")!
                    let library = try metalDevice.makeLibrary(URL: url)
                    
                    // Create a function with a specific name.
                    let function = library.makeFunction(name: "main0")!
                    
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
        
        public override func process(video: VideoBuffer) {
            lock.locked {
                if let imageBuffer = CMSampleBufferGetImageBuffer(video.sampleBuffer) {
                    process(pixelBuffer1: imageBuffer, pixelBuffer2: imageBuffer)
                }
            }
            
            super.process(video: video)
        }
        
        private func process(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) {
            guard
                let computePipelineState = computePipelineState,
                let metalDevice = metalDevice,
                let commandQueue = commandQueue,
                let textureCache = textureCache
            else {
                return
            }
            
            do {
                // Converts the pixel buffer in a Metal texture.
                let inputTextures1 = try pixelBuffer1.cvMTLTexture(textureCache: textureCache)
                let inputTextures2 = try pixelBuffer2.cvMTLTexture(textureCache: textureCache)
                
                guard inputTextures1.count == inputTextures2.count else {
                    assert(false); return
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
                }
            }
            catch {
                logAVError(error)
            }
            
            return
        }

    }
}


public extension VideoSetup {
    class Recolor : VideoSetupProcessor {
        public init(kind: VideoProcessor.Kind = .capture) {
            super.init(kind: kind) {
                return VideoProcessor.Recolor(next: $0)
            }
        }
    }
}
