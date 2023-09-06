//
//  AVFoundation.Capture.swift
//  Utils
//
//  Created by Ivan Kh on 08.12.2022.
//

import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
@available(iOSApplicationExtension, unavailable)
public extension AVCaptureVideoOrientation {
    init?(_ src: UIInterfaceOrientation) {
        switch src {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
    
    static var fromInterface: AVCaptureVideoOrientation? {
        guard let src = UIApplication.shared.interfaceOrientationOnMain else { return nil }
        return AVCaptureVideoOrientation(src)
    }
}
#endif

#if canImport(UIKit)
@available(iOSApplicationExtension, unavailable)
public extension AVCaptureConnection {
    func updateOrientationFromInterface() {
        guard let orientation = AVCaptureVideoOrientation.fromInterface else { return }
        videoOrientation = orientation
    }
}
#endif

#if canImport(UIKit)
@available(iOSApplicationExtension, unavailable)
public extension AVCaptureVideoDataOutput {
    func updateOrientationFromInterface() {
        connection(with: .video)?.updateOrientationFromInterface()
    }
}
#endif
