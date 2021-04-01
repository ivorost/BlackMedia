//
//  AV.Reader.swift
//  Core
//
//  Created by Ivan Kh on 16.02.2021.
//

import Foundation
import AVFoundation


public extension VideoProcessor {
    class AssetReader : Session.Proto, Flushable.Proto {
        enum Error : Swift.Error {
            case missedVideoTrack
        }
        
        public private(set) var videoSize: CGSize?
        private let next: VideoProcessor.Proto
        private let url: URL
        private var file: FileHandle?
        private var reader: AVAssetReader?
        private var videoOutput: AVAssetReaderSampleReferenceOutput?
        private var ID: UInt = 0
        private var startTime: Double?
        private var startDate: Date?
        private var postponedSampleBuffer: CMSampleBuffer?

        init(url: URL, next: VideoProcessor.Proto) {
            self.url = url
            self.next = next
        }
        
        public func start() throws {
            let asset = AVAsset(url: url)

            guard let track = asset.tracks(withMediaType: .video).first
            else { throw Error.missedVideoTrack }

            let reader = try AVAssetReader(asset: asset)
            let videoOutput = AVAssetReaderSampleReferenceOutput(track: track)

            reader.add(videoOutput)
            self.file = try FileHandle(forReadingFrom: url)
            self.reader = reader
            self.reader?.startReading()
            self.videoOutput = videoOutput
            self.videoSize = track.naturalSize
        }
        
        public func stop() {
            reader?.cancelReading()
            
            ID = 0
            reader = nil
            videoOutput = nil
        }

        public func flush() {
            do {
                try popSample()
            }
            catch {
                logAVError(error)
            }
        }
                
        private func popSample() throws {
            guard let file = file else { assert(false); return }
            guard let videoOutput = videoOutput else { assert(false); return }
            guard let sampleBuffer = postponedSampleBuffer ?? videoOutput.copyNextSampleBuffer() else { return }
            guard CMSampleBufferGetNumSamples(sampleBuffer) == 1 else { return }
            
            if let startDate = startDate, let startTime = startTime {
                let systemSecondsLeft = Date().timeIntervalSince(startDate)
                let videoSecondsLeft = sampleBuffer.presentationSeconds - startTime
                
                if systemSecondsLeft < videoSecondsLeft {
                    postponedSampleBuffer = sampleBuffer
                    return
                }
            }
            else {
                startDate = Date()
                startTime = sampleBuffer.presentationSeconds
            }
            
            postponedSampleBuffer = nil
            
            let size = CMSampleBufferGetSampleSize(
                sampleBuffer,
                at: 0)
            guard let offset = CMGetAttachment(
                    sampleBuffer,
                    key: kCMSampleBufferAttachmentKey_SampleReferenceByteOffset,
                    attachmentModeOut: nil) as? UInt64
            else { assert(false); return }
            
            file.seek(toFileOffset: offset)
            let data = file.readData(ofLength: size)
            var blockBuffer: CMBlockBuffer?
            let blockBufferData = UnsafeMutablePointer<Int8>.allocate(capacity: data.count)
            
            data.bytes {
                blockBufferData.assign(from: $0.assumingMemoryBound(to: Int8.self), count: data.count)
            }
            
            try check(status: CMBlockBufferCreateWithMemoryBlock(
                        allocator: kCFAllocatorDefault,
                        memoryBlock: blockBufferData,
                        blockLength: data.count,
                        blockAllocator: kCFAllocatorDefault,
                        customBlockSource: nil,
                        offsetToData: 0,
                        dataLength: data.count,
                        flags: 0,
                        blockBufferOut: &blockBuffer),
                      message: "createReadonlyBlockBuffer")
            
            if let blockBuffer = blockBuffer {
                CMSampleBufferSetDataBuffer(sampleBuffer, newValue: blockBuffer)
            }
                        
            next.process(video: VideoBuffer(ID: ID, buffer: sampleBuffer))
            ID += 1
        }
    }
}


public extension VideoSetup {
    class AssetReader : VideoSetupSlave {
        private let url: URL
        public private(set) var processor: VideoProcessor.AssetReader?
        public let flushable = Flushable.Proxy()
        
        public init(url: URL, root: VideoSetupProtocol) {
            self.url = url
            super.init(root: root)
        }
        
        public override func session(_ session: Session.Proto, kind: Session.Kind) {
            if kind == .initial {
                let video = root.video(VideoProcessor(), kind: .capture)
                let reader = VideoProcessor.AssetReader(url: url, next: video)
                
                self.processor = reader
                flushable.inner = reader
                root.session(reader, kind: .input)
            }
        }
    }
}
