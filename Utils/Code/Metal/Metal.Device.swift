//
//  MetalKit.Device.swift
//  Utils
//
//  Created by Ivan Kh on 06.03.2021.
//

import Metal
import CoreVideo

public extension MTLDevice {
    func makeTextureCache() -> CVMetalTextureCache? {
        var result: CVMetalTextureCache?
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault,
                                  nil,
                                  self,
                                  nil,
                                  &result)
        
        return result
    }
}
