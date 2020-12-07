//
//  Video.Input.File.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 30.04.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AVFoundation


class VideoAssetOutput : AssetOutput, VideoOutputProtocol {
    init(asset: AVAssetWriter, assetSession: AssetWriterSession, settings: CaptureSettings) {
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings.data)
        super.init(writer: asset, writerSession: assetSession, input: input)
    }

    init(asset: AVAssetWriter, assetSession: AssetWriterSession, input: AVAssetWriterInput) {
        super.init(writer: asset, writerSession: assetSession, input: input)
    }

    func process(video: VideoBuffer) {
        process(sampleBuffer: video.sampleBuffer)
    }
}


class VideoAssetOutputPositioned : VideoAssetOutput {
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    private let videoSize: CGSize
    private let assetRect: CGRect
    
    init(asset: AVAssetWriter,
         assetSession: AssetWriterSession,
         settings: CaptureSettings,
         videoSize: CGSize,
         assetRect: CGRect) {
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings.data)
       
        self.adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        self.videoSize = videoSize
        self.assetRect = assetRect
        
        super.init(asset: asset, assetSession: assetSession, input: input)
    }

    override func append(sampleBuffer: CMSampleBuffer) {
        guard
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) as CVPixelBuffer?
            else { assert(false); return }
        
        // Now it's only one stream in the resulting video, and on place of second one just gray area.
        // I think the best idea is to try keeping created pixel buffer and overwrite each time approprieate area in it.
        // But not sure about efficient video size in this case.
        // Maybe it's better to try combing input stream buffers and write them at a time.
        
//        if let positionedPixelBuffer = position(pixelBuffer: pixelBuffer) {
//            pixelBuffer = positionedPixelBuffer
//        }

        adaptor.append(pixelBuffer, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
    }

    func position(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let context = CIContext()
        var image = CIImage(cvImageBuffer: pixelBuffer)
        var result: CVPixelBuffer? = nil

        image = image.transformed(by: CGAffineTransform(scaleX: assetRect.width / image.extent.width,
                                                        y: assetRect.height / image.extent.height))
        image = image.transformed(by: CGAffineTransform(translationX: assetRect.origin.x,
                                                        y: assetRect.origin.y))

        CVPixelBufferCreate(nil,
                            Int(videoSize.width),
                            Int(videoSize.height),
                            CVPixelBufferGetPixelFormatType(pixelBuffer),
                            nil,
                            &result)

        if let result = result, #available(OSX 10.11, *) {
            context.render(image, to: result)
        }
        else {
            assert(false)
            return nil
        }
        
        return result
    }
}
