//
//  File.swift
//  
//
//  Created by Ivan Kh on 18.04.2023.
//

import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

public extension Capture {
    class Session : BlackMedia.Session.Proto {
        let inner = AVCaptureSession()

        public func start() throws {
            inner.startRunning()

            #if canImport(UIKit)
            NotificationCenter.default.addObserver(self, selector: #selector(appHasEnteredBackground),
                                                   name: UIApplication.willResignActiveNotification,
                                                   object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground),
                                                   name: UIApplication.willEnterForegroundNotification,
                                                   object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted),
                                                   name: .AVCaptureSessionWasInterrupted,
                                                   object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded),
                                                   name: .AVCaptureSessionInterruptionEnded,
                                                   object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError),
                                                   name: .AVCaptureSessionRuntimeError,
                                                   object: nil)
            #endif
        }

        public func stop() {
            inner.stopRunning()
            NotificationCenter.default.removeObserver(self)
        }

        @objc private func appHasEnteredBackground() {
        }

        @objc private func appWillEnterForeground() {
        }

        @objc func sessionRuntimeError(notification: NSNotification) {
            guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }

            DispatchQueue.main.async {
                if !self.inner.isRunning {
                    self.inner.startRunning()
                }
            }

            debugPrint("AVCaptureSession: sessionRuntimeError \(error)")
        }

        @objc func sessionWasInterrupted(notification: NSNotification) {
            guard let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
                let reasonIntegerValue = userInfoValue.integerValue,
                let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue)
            else { return }

            switch reason {
            case .videoDeviceNotAvailableInBackground:
                debugPrint("AVCaptureSession: sessionWasInterrupted.videoDeviceNotAvailableInBackground")

            case .audioDeviceInUseByAnotherClient:
                debugPrint("AVCaptureSession: sessionWasInterrupted.audioDeviceInUseByAnotherClient")

            case .videoDeviceInUseByAnotherClient:
                debugPrint("AVCaptureSession: sessionWasInterrupted.videoDeviceInUseByAnotherClient")

            case .videoDeviceNotAvailableWithMultipleForegroundApps:
                debugPrint("AVCaptureSession: sessionWasInterrupted.videoDeviceNotAvailableWithMultipleForegroundApps")

            case .videoDeviceNotAvailableDueToSystemPressure:
                debugPrint("AVCaptureSession: sessionWasInterrupted.videoDeviceNotAvailableDueToSystemPressure")

            @unknown default:
                break
            }
        }

        @objc func sessionInterruptionEnded(notification: NSNotification) {
            debugPrint("AVCaptureSession: sessionInterruptionEnded")

            DispatchQueue.global().async {
                if !self.inner.isRunning {
                    self.inner.startRunning()
                }
            }
        }
    }
}
