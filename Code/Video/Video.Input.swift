import AVFoundation

@available(iOSApplicationExtension, unavailable)
extension Video.Setup {
    public class Input : Slave {
        let session: Capture.Session
        private let input: AVCaptureInput

        public init(root: Video.Setup.Proto, session: Capture.Session, input: AVCaptureInput) {
            self.input = input
            self.session = session
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
                root.session(session, kind: .avCapture)
                root.session(inputConfiguration(), kind: .other)
            }
        }
        
        fileprivate func inputSession() -> Session.Proto {
            return Capture.Input(session: session.inner, input: input)
        }
        
        fileprivate func inputConfiguration() -> Session.Proto {
            return Session.shared
        }
        
        private func capture(next: Video.Processor.AnyProto) -> Video.Output {
            return Video.Output(inner: .video32BGRA(session.inner),
                                queue: BlackMedia.Capture.queue,
                                next: next)
        }
    }
}

public extension Video.EncoderConfig {
    init(codec: AVVideoCodecType, format: AVCaptureDevice.Format) {
        self.init(codec: codec, input: format.dimensions, output: format.dimensions)
    }
}
