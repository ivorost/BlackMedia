//
//  MetalKit.CVMetalTexture.swift
//  Capture
//
//  Created by Ivan Kh on 03.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import MetalKit

extension CVPixelBuffer {
    func cvMetalTexture(textureCache: CVMetalTextureCache) -> [CVMetalTexture] {
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
                //        case kCVPixelFormatType_32ABGR:
                //            metalPixelFormat = .abgr8Unorm
                //        case kCVPixelFormatType_32ARGB:
            //            metalPixelFormat = .argb8Unorm
            case kCVPixelFormatType_32BGRA:
                metalPixelFormat = .rgba8Unorm
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
            let status = CVMetalTextureCacheCreateTextureFromImage(nil,
                                                      textureCache,
                                                      self,
                                                      nil,
                                                      metalPixelFormat,
                                                      width,
                                                      height,
                                                      planeIndex,
                                                      &cvTexture)
            
            if let cvTexture = cvTexture {
                result.append(cvTexture)
            }
        }
        
        return result
    }
}
