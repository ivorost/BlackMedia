//
//  Metal.PixelBuffer.swift
//  Core
//
//  Created by Ivan Kh on 06.03.2021.
//

import Metal
import CoreVideo


class MetalProcessor {
}


extension MTLComputeCommandEncoder {
    func threadGroupCount() -> MTLSize {
        return MTLSizeMake(8, 8, 1)
    }
 
    func threadGroups(size: CGSize) -> MTLSize {
        let groupCount = threadGroupCount()
        return MTLSizeMake(Int(size.width) / groupCount.width, Int(size.height) / groupCount.height, 1)
    }
}

 
extension MetalProcessor {
    class PixelBuffer {
        let textureCache: CVMetalTextureCache
        let commandQueue: MTLCommandQueue
        let computePipelineState: MTLComputePipelineState
        let metalDevice: MTLDevice
        let customScope: MTLCaptureScope

        init?(library url: URL, function name: String) throws {
            guard let metalDevice = MTLCreateSystemDefaultDevice() else { return nil }
            guard let commandQueue = metalDevice.makeCommandQueue() else { return nil }
            let library = try metalDevice.makeLibrary(URL: url)
            guard let function = library.makeFunction(name: name) else { return nil }
            let computePipelineState = try metalDevice.makeComputePipelineState(function: function)
            guard let textureCache = metalDevice.makeTextureCache() else { return nil }
            
            self.metalDevice  = metalDevice
            self.commandQueue = commandQueue
            self.textureCache = textureCache
            self.computePipelineState = computePipelineState
            
            let sharedCapturer = MTLCaptureManager.shared()
            customScope = sharedCapturer.makeCaptureScope(device: metalDevice)
            // Add a label if you want to capture it from XCode's debug bar
            customScope.label = "Pls debug me"
            // If you want to set this scope as the default debug scope, assign it to MTLCaptureManager's defaultCaptureScope
            sharedCapturer.defaultCaptureScope = customScope
        }
        
        func processAndWait(pixelBuffer1: CVPixelBuffer,
                            pixelBuffer2: CVPixelBuffer,
                            initialize: MTLComputeCommandEncoder.Func = { _ in },
                            complete: MTLComputeCommandEncoder.Func = { _ in }) throws {
            // Converts the pixel buffer in a Metal texture.
            let inputTextures1 = try pixelBuffer1.cvMTLTexture(textureCache: textureCache)
            let inputTextures2 = try pixelBuffer2.cvMTLTexture(textureCache: textureCache)
            
            guard inputTextures1.count == inputTextures2.count else { assert(false); return }

            let initializeInternal = { (computeCommandEncoder: MTLComputeCommandEncoder) -> Void in
                var textureIndex = 0

                for inputTexture in inputTextures1 {
                    computeCommandEncoder.setTexture(inputTexture, index: textureIndex)
                    textureIndex += 1
                }

                for inputTexture in inputTextures2 {
                    computeCommandEncoder.setTexture(inputTexture, index: textureIndex)
                    textureIndex += 1
                }
                
                initialize(computeCommandEncoder)
            }
            
            process(size: pixelBuffer1.size, initialize : initializeInternal, complete: complete)
        }
        
        private func process(size: CGSize,
                             initialize: MTLComputeCommandEncoder.Func,
                             complete: MTLComputeCommandEncoder.Func) {

//            customScope.begin()
//            MTLCaptureManager.shared().startCapture(commandQueue: commandQueue)

            // Create a command buffer
            let commandBuffer = commandQueue.makeCommandBuffer()!
            
            // Create a compute command encoder.
            let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
            
            // Set the compute pipeline state for the command encoder.
            computeCommandEncoder.setComputePipelineState(computePipelineState)
            
            // execute
            initialize(computeCommandEncoder)

            // Encode a threadgroup's execution of a compute function
            computeCommandEncoder.dispatchThreadgroups(
                computeCommandEncoder.threadGroups(size: size),
                threadsPerThreadgroup: computeCommandEncoder.threadGroupCount())
            
            // End the encoding of the command.
            computeCommandEncoder.endEncoding()
            
            // Commit the command buffer for execution.
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            complete(computeCommandEncoder)
        }
    }
}
