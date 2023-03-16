
import AVFoundation


@available(iOSApplicationExtension, unavailable)
extension Video.Setup {
    public class Input : Slave {
        let avCaptureSession: AVCaptureSession
        private let input: AVCaptureInput

        public init(root: Video.Setup.Proto, session: AVCaptureSession, input: AVCaptureInput) {
            self.input = input
            self.avCaptureSession = session
            super.init(root: root)
        }

        public override func session(_ session: Session.Proto, kind: Session.Kind) {
            if kind == .initial {
                let video = root.video(Video.Processor.shared, kind: .capture)
                let capture = capture(next: video)
                #if os(iOS)
                let captureOrientation = Video.CaptureOrientation(capture.inner.output)
                #endif
                
                root.session(inputSession(), kind: .input)
                #if os(iOS)
                root.session(captureOrientation, kind: .other)
                #endif
                root.session(capture, kind: .capture)
                root.session(avCaptureSession, kind: .avCapture)
                root.session(inputConfiguration(), kind: .other)
            }
        }
        
        fileprivate func inputSession() -> Session.Proto {
            return Capture.Input(session: avCaptureSession, input: input)
        }
        
        fileprivate func inputConfiguration() -> Session.Proto {
            return Session.shared
        }
        
        private func capture(next: Video.Processor.AnyProto) -> Video.Output {
            return Video.Output(inner: .video32BGRA(avCaptureSession),
                                queue: Core.Capture.queue,
                                next: next)
        }
    }
}


@available(iOSApplicationExtension, unavailable)
extension Video.Setup {
    public class DeviceInput : Input {
        private var deviceInput: Capture.DeviceInput
        private let configure: Capture.DeviceInputConfiguration.Func?

        public init(root: Video.Setup.Proto,
                    session: AVCaptureSession,
                    input: AVCaptureDeviceInput,
                    format: AVCaptureDevice.Format,
                    configure: Capture.DeviceInputConfiguration.Func? = nil) {

            self.configure = configure
            self.deviceInput = Capture.DeviceInput(session: session,
                                                   input: input,
                                                   format: format)

            super.init(root: root, session: session, input: input)
        }
        
        override func inputSession() -> Session.Proto {
            return deviceInput
        }
        
        override func inputConfiguration() -> Session.Proto {
            return Capture.DeviceInputConfiguration(input: deviceInput, configure: configure)
        }
    }
}


public extension Video.EncoderConfig {
    init(codec: AVVideoCodecType, format: AVCaptureDevice.Format) {
        self.init(codec: codec, input: format.dimensions, output: format.dimensions)
    }
}
