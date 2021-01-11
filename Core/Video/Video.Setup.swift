//
//  Video.Setup.swift
//  Capture
//
//  Created by Ivan Kh on 17.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//


import AVFoundation
#if os(OSX)
import AppKit
#endif


extension VideoProcessor.Kind {
    static let capture = VideoProcessor.Kind(rawValue: "capture")
    static let duplicatesFree = VideoProcessor.Kind(rawValue: "duplicatesFree")
    static let duplicatesNext = VideoProcessor.Kind(rawValue: "duplicatesNext")
    static let encoder = VideoProcessor.Kind(rawValue: "encoder")
    static let decoder = VideoProcessor.Kind(rawValue: "decoder")
    static let serializer = VideoProcessor.Kind(rawValue: "serializer")
    static let deserializer = VideoProcessor.Kind(rawValue: "deserializer")
    static let preview = VideoProcessor.Kind(rawValue: "preview")
}


protocol VideoSetupProtocol : CaptureSetup.Proto {
    func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol
}


extension VideoProcessor {
    typealias Setup = VideoSetupProtocol
}


extension VideoSetup {
    typealias Base = VideoSetup
}


class VideoSetup : VideoSetupProtocol {
    static let shared = VideoSetup()
    
    func complete() -> SessionProtocol? {
        return nil
    }
    
    func video(_ video: VideoProcessor.Proto, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        return video
    }

    func data(_ data: DataProcessor.Proto, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        return data
    }

    func session(_ session: Session.Proto, kind: Session.Kind) {
    }
}


class VideoSetupSlave : VideoSetup {
    private(set) weak var _root: VideoSetupProtocol?
    
    init(root: VideoSetupProtocol) {
        self._root = root
    }
    
    var root: VideoSetupProtocol {
        return _root ?? VideoSetup.shared
    }
}


class VideoSetupChain : VideoSetupProtocol {
    private let _next: VideoSetupProtocol

    init(next: VideoSetupProtocol) {
        self._next = next
    }

    func next() -> VideoSetupProtocol {
        return _next
    }
    
    func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        return self.next().video(video, kind: kind)
    }
    
    func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        return self.next().data(data, kind: kind)
    }
    
    func session(_ session: SessionProtocol, kind: Session.Kind) {
        return self.next().session(session, kind: kind)
    }
    
    func complete() -> SessionProtocol? {
        return self.next().complete()
    }
}


class VideoSetupVector : CaptureSetup.VectorBase<VideoSetupProtocol>, VideoSetupProtocol {
    func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        return vector.reduce(video) { $1.video($0, kind: kind) }
    }
}


func broadcast(_ x: [VideoSetupProtocol?]) -> VideoSetupProtocol? {
    broadcast(x, create: { VideoSetupVector($0) })
}


class VideoSetupProcessor : VideoSetup {
    
    private let create: (VideoProcessor.Proto) -> VideoProcessor.Proto
    private let kind: VideoProcessor.Kind
    
    convenience init(kind: VideoProcessor.Kind, video: VideoOutputProtocol) {
        self.init(kind: kind) { VideoProcessor(prev: video, next: $0) }
    }
    
    init(kind: VideoProcessor.Kind, create: @escaping (VideoProcessor.Proto) -> VideoProcessor.Proto) {
        self.create = create
        self.kind = kind
    }
    
    override func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        var result = video
        
        if kind == self.kind {
            result = create(result)
        }
        
        return result
    }
}


class VideoSetupDataProcessor : VideoSetup {
    
    private let data: DataProcessorProtocol
    private let kind: DataProcessor.Kind
    
    init(data: DataProcessorProtocol, kind: DataProcessor.Kind) {
        self.data = data
        self.kind = kind
    }
    
    override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        var result = data
        
        if kind == self.kind {
            result = DataProcessor(prev: self.data, next: result)
        }
        
        return super.data(result, kind: kind)
    }
}


#if os(OSX)
class VideoSetupCheckbox : VideoSetupChain {
    private let checkbox: NSButton
    
    init(next: VideoSetupProtocol, checkbox: NSButton) {
        self.checkbox = checkbox
        super.init(next: next)
    }
    
    override func next() -> VideoSetupProtocol {
        return checkbox.state == .on
            ? super.next()
            : VideoSetup.shared
    }
}
#endif


fileprivate class VideoSetupSessionAdapter : VideoSetup {
    private let session: Session.Setup
    
    init(_ session: Session.Setup) {
        self.session = session
    }

    override func session(_ session: Session.Proto, kind: Session.Kind) {
        self.session.session(session, kind: kind)
    }
    
    override func complete() -> Session.Proto? {
        return self.session.complete()
    }
}

fileprivate class VideoSetupCaptureAdapter : VideoSetupSessionAdapter {
    private let capture: CaptureSetup.Proto
    
    init(_ capture: CaptureSetup.Proto) {
        self.capture = capture
        super.init(capture)
    }
    
    override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        return capture.data(data, kind: kind)
    }
}


extension VideoSetup {
    class External: VideoSetupSlave {
        private(set) var video: VideoProcessor.Proto = VideoProcessor.shared
        
        override func session(_ session: Session.Proto, kind: Session.Kind) {
            if kind == .initial {
                let video = root.video(VideoProcessor.shared, kind: .capture)
                self.video = video
            }
        }
    }
}


func cast(video session: Session.Setup) -> VideoSetupProtocol {
    return VideoSetupSessionAdapter(session)
}


func cast(video capture: CaptureSetup.Proto) -> VideoSetupProtocol {
    return VideoSetupCaptureAdapter(capture)
}


func cast(video data: DataProcessor.Setup) -> VideoSetupProtocol {
    return cast(video: cast(capture: data))
}