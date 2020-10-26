//
//  QuartzCore.Layer.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 02.07.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import QuartzCore

extension CALayer {
    func animatePulsation(from: CGFloat, to: CGFloat, duration: CFTimeInterval) {
        let pulseAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        pulseAnimation.duration = duration
        pulseAnimation.fromValue = from
        pulseAnimation.toValue = to
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .greatestFiniteMagnitude
        
        add(pulseAnimation, forKey: "animateOpacity")
    }
}
