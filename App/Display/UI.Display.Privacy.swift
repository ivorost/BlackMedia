//
//  Features.Screen.Privacy.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 09.06.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation


fileprivate extension String {
    static let screenPane: String
        = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
}


// Mac OS 10.15. Apple still doesn't provide API for display recording authorization
class AVDisplayRecordingPrivacyStatus : PrivacyStatus {
    static let shared = AVDisplayRecordingPrivacyStatus()
    
    var defined: Bool? {
        return true
    }
    
    var authorized: Bool? {
        return AVCaptureScreenInput.canRecordScreen
    }
    
    var panePath: String {
        return .screenPane
    }
    
    func request(callback: Func?) {
        callback?()
    }
}
