//
//  Utility.Environment.swift
//  Camera
//
//  Created by Ivan Kh on 11.04.2023.
//  Copyright © 2023 Ivan Kh. All rights reserved.
//

import SwiftUI

struct AnimationDurationKey: EnvironmentKey {
    static let defaultValue: CFTimeInterval = 0.35
}

extension EnvironmentValues {
    var animationDuration: CFTimeInterval {
        get { self[AnimationDurationKey.self] }
        set { self[AnimationDurationKey.self] = newValue }
    }
}
