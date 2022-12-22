//
//  Video.Orientation.Change.swift
//  Core
//
//  Created by Ivan Kh on 08.12.2022.
//

#if os(iOS)

import UIKit
import AVFoundation


@available(iOSApplicationExtension, unavailable)
public extension Video {
    class CaptureOrientation {
        private let output: AVCaptureVideoDataOutput
        
        init(_ output: AVCaptureVideoDataOutput) {
            self.output = output
        }
    }
}


@available(iOSApplicationExtension, unavailable)
extension Video.CaptureOrientation : Session.Proto {
    public func start() throws {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(rotated(_ :)),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)

    }
    
    public func stop() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func rotated(_ notification: Notification) {
        output.updateOrientationFromInterface()
    }
}

#endif
