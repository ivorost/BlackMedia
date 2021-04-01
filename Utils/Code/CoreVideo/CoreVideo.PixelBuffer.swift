//
//  CoreVideo.PixelBuffer.swift
//  Utils
//
//  Created by Ivan Kh on 06.03.2021.
//

import CoreVideo

public extension CVPixelBuffer {
    var size: CGSize {
        return CGSize(width: CVPixelBufferGetWidth(self),
                      height: CVPixelBufferGetHeight(self))
    }
}
