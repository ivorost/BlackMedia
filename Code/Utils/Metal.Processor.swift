//
//  Metal.PixelBuffer.swift
//  Core
//
//  Created by Ivan Kh on 06.03.2021.
//

import Metal
import CoreVideo
import BlackUtils


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
    class TwoBitmaps {
        enum BufferWidth {
            case none
            case constant(value: Int)
            case threadExecutionWidth
        }

        private let textureCache: CVMetalTextureCache
        private let commandQueue: MTLCommandQueue
        private let computePipelineState: MTLComputePipelineState
        private let metalDevice: MTLDevice
        private let customScope: MTLCaptureScope
        private let bufferWidth: BufferWidth

        private lazy var dataBuffer: MTLBuffer? = {
            switch bufferWidth {
            case .none: return metalDevice.makeBuffer(length: 1)
            case .constant(let value): return metalDevice.makeBuffer(
                length: value * MemoryLayout<Int32>.size,
                options: .storageModeShared)
            case .threadExecutionWidth: return metalDevice.makeBuffer(
                length: computePipelineState.threadExecutionWidth * MemoryLayout<Int32>.size,
                options: .storageModeShared)
            }
        }()

        init?(library url: URL, function name: String, buffer width: BufferWidth = .none) throws {
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
            self.bufferWidth = width
            
            let sharedCapturer = MTLCaptureManager.shared()
            customScope = sharedCapturer.makeCaptureScope(device: metalDevice)
            // Add a label if you want to capture it from XCode's debug bar
            customScope.label = "Pls debug me"
            // If you want to set this scope as the default debug scope, assign it to MTLCaptureManager's defaultCaptureScope
            sharedCapturer.defaultCaptureScope = customScope
        }

        var buffer: UnsafeMutableBufferFloatPointer {
            guard let dataBuffer else { return UnsafeMutableBufferFloatPointer(start: nil, count: 0) }

            return UnsafeMutableBufferFloatPointer(
                start: dataBuffer.contents().bindMemory(to: Int32.self, capacity: dataBuffer.length),
                count: dataBuffer.length / MemoryLayout<Int32>.size)
        }

        func processAndWait(pixelBuffer1: CVPixelBuffer, pixelBuffer2: CVPixelBuffer) throws {
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
            }
            
            process(size: pixelBuffer1.size, initialize : initializeInternal)
        }
        
        private func process(size: CGSize, initialize: (MTLComputeCommandEncoder) -> Void) {

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

            if let dataBuffer {
                computeCommandEncoder.setBuffer(dataBuffer, offset: 0, index: 0)
            }

            let threadGroupCount = MTLSizeMake(dataBuffer!.length / MemoryLayout<Int32>.size, 1, 1)
            let threadGroups = MTLSizeMake(Int(size.width) / threadGroupCount.width,
                                               Int(size.height) / threadGroupCount.height,
                                               1)

//            let threadGroups = computeCommandEncoder.threadGroups(size: size)
//            let threadGroupCount = computeCommandEncoder.threadGroupCount()

            // Encode a threadgroup's execution of a compute function
            computeCommandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
            
            // End the encoding of the command.
            computeCommandEncoder.endEncoding()
            
            // Commit the command buffer for execution.
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
}
