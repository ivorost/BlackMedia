
import AVFoundation

class VideoInput : CaptureInput {

    private let device: AVCaptureDevice
    private let format: AVCaptureDevice.Format

    init(session: AVCaptureSession, device: AVCaptureDevice, format: AVCaptureDevice.Format) {
        self.device = device
        self.format = format
        
        super.init(session: session)
    }
    
    override func createInput() throws -> AVCaptureInput {
        return try AVCaptureDeviceInput(device: device)
    }
    
    override func start() throws {
        do {
            try device.lockForConfiguration()
            device.activeFormat = format

            try super.start()
        }
        catch {
            device.unlockForConfiguration()
        }
    }
    
    override func stop() {
        logAVPrior("video input stop")
        super.stop()
        device.unlockForConfiguration()
    }
    
//    assert(formatNotChanged(sampleBuffer))

//    func formatNotChanged(_ sampleBuffer: CMSampleBuffer) -> Bool {
//        let sampleDimentions = CMVideoFormatDescriptionGetDimensions(CMSampleBufferGetFormatDescription(sampleBuffer)!)
//
//        return format.dimensions == sampleDimentions || format.dimensions == sampleDimentions.turn()
//    }
}
