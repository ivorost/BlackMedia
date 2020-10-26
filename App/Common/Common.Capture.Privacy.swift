//
//  Features.Screen.Privacy.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 09.06.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation


fileprivate extension String {
    static let videoPane: String
        = "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
    static let audioPane: String
        = "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
}


class AVCaptureDevicePrivacyStatus : PrivacyStatus {

    static let video = AVCaptureDevicePrivacyStatus(for: .video, pane: .videoPane)
    static let audio = AVCaptureDevicePrivacyStatus(for: .audio, pane: .audioPane)

    private let mediaType: AVMediaType
    private let pane: String
    
    init(for mediaType: AVMediaType, pane: String) {
        self.mediaType = mediaType
        self.pane = pane
    }
    
    var defined: Bool? {
        if #available(OSX 10.14, *) {
            return AVCaptureDevice.authorizationStatus(for: mediaType) != .notDetermined
        }
        else {
            return nil
        }
    }
    
    var authorized: Bool? {
        if #available(OSX 10.14, *) {
            return AVCaptureDevice.authorizationStatus(for: mediaType) == .authorized
        }
        else {
            return nil
        }
    }
    
    var panePath: String {
        return pane
    }
    
    func request(callback: Func?) {
        if #available(OSX 10.14, *) {
            AVCaptureDevice.requestAccess(for: mediaType) { _ in
                callback?()
            }
        }
        else {
            callback?()
        }
    }
}
