//
//  Audio.Utilities.swift
//  Core
//
//  Created by Ivan Kh on 03.04.2023.
//

import AudioToolbox

public extension ProcessorToolbox {
    class Vibrate: ProcessorProtocol {
        public typealias Value = TValue

        public init() {}

        public func process(_ value: TValue) {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
}
