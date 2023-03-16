//
//  CoreGraphics.Image.swift
//  Utils
//
//  Created by Ivan Kh on 10.04.2023.
//

import CoreGraphics

public extension CGContext {
    var size: CGSize {
        CGSize(width: CGFloat(width), height: CGFloat(height))
    }

    func drawAspectFill(image: CGImage) {
        let selfRect = boundingBoxOfClipPath
        let coef = max(CGFloat(selfRect.width) / CGFloat(image.width), CGFloat(selfRect.height) / CGFloat(image.height))
        let width = CGFloat(image.width) * coef
        let height = CGFloat(image.height) * coef

        saveGState()
        scaleBy(x: 1, y: -1)
        draw(image, in: CGRect(x: selfRect.minX + (selfRect.width - width) / 2,
                               y: selfRect.minY - selfRect.height - (height - selfRect.height) / 2,
                               width: width,
                               height: height))
        restoreGState()
    }
}
