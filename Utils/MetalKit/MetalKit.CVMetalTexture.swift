//
//  MetalKit.CVMetalTexture.swift
//  Capture
//
//  Created by Ivan Kh on 03.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import MetalKit

extension CVPixelBuffer {
    func cvMetalTexture(textureCache: CVMetalTextureCache) throws -> [CVMetalTexture] {
        var result = [CVMetalTexture]()
        var metalPixelFormat : MTLPixelFormat
                
        let imageBufferPixelFormat = CVPixelBufferGetPixelFormatType(self)
        
        var planes = CVPixelBufferGetPlaneCount(self)
        
        if planes == 0 {
            planes = 1
        }
        
        for planeIndex in 0 ..< planes {
            let width = CVPixelBufferGetWidthOfPlane(self, planeIndex)
            let height = CVPixelBufferGetHeightOfPlane(self, planeIndex)
            
            switch imageBufferPixelFormat {
            case kCVPixelFormatType_32RGBA:
                metalPixelFormat = .rgba8Unorm
            case kCVPixelFormatType_32BGRA:
                metalPixelFormat = .bgra8Unorm
            case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
                if planeIndex == 0 {
                    metalPixelFormat = .r8Unorm
                }
                else {
                    metalPixelFormat = .rg8Unorm
                }
            default:
                assert(false, "EECVImageBufferViewer.presentCVImageBuffer(): Unsupported pixel format \(imageBufferPixelFormat)")
                metalPixelFormat = .invalid
            }
            
            var cvTexture : CVMetalTexture?
            try checkStatus(CVMetalTextureCacheCreateTextureFromImage(nil,
                                                                      textureCache,
                                                                      self,
                                                                      nil,
                                                                      metalPixelFormat,
                                                                      width,
                                                                      height,
                                                                      planeIndex,
                                                                      &cvTexture),
                            "CVPixelBuffer.cvMetalTexture.CVMetalTextureCacheCreateTextureFromImage")
            
            if let cvTexture = cvTexture {
                result.append(cvTexture)
            }
        }
        
        return result
    }
    
    func cvMTLTexture(textureCache: CVMetalTextureCache) throws -> [MTLTexture] {
        var result = [MTLTexture]()
        
        for metalTexture in try cvMetalTexture(textureCache: textureCache)  {
            if let mtlTexture = CVMetalTextureGetTexture(metalTexture) {
                result.append(mtlTexture)
            }
            else {
                assert(false)
            }
        }
        
        return result
    }
}
