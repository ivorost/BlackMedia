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


public extension VideoProcessor.Kind {
    static let capture = VideoProcessor.Kind(rawValue: "capture")
    static let duplicatesFree = VideoProcessor.Kind(rawValue: "duplicatesFree")
    static let duplicatesNext = VideoProcessor.Kind(rawValue: "duplicatesNext")
    static let encoder = VideoProcessor.Kind(rawValue: "encoder")
    static let decoder = VideoProcessor.Kind(rawValue: "decoder")
    static let serializer = VideoProcessor.Kind(rawValue: "serializer")
    static let deserializer = VideoProcessor.Kind(rawValue: "deserializer")
    static let preview = VideoProcessor.Kind(rawValue: "preview")
}


public protocol VideoSetupProtocol : CaptureSetup.Proto {
    func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol
}


extension VideoProcessor {
    typealias Setup = VideoSetupProtocol
}


extension VideoSetup {
    typealias Base = VideoSetup
}


public class VideoSetup : VideoSetupProtocol {
    static let shared = VideoSetup()
    
    public init() {}
    
    public func complete() -> SessionProtocol? {
        return nil
    }
    
    public func video(_ video: VideoProcessor.Proto, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        return video
    }

    public func data(_ data: DataProcessor.Proto, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        return data
    }

    public func session(_ session: Session.Proto, kind: Session.Kind) {
    }
}


public class VideoSetupSlave : VideoSetup {
    private(set) weak var _root: VideoSetupProtocol?
    
    public init(root: VideoSetupProtocol) {
        self._root = root
    }
    
    var root: VideoSetupProtocol {
        return _root ?? VideoSetup.shared
    }
}


public class VideoSetupChain : VideoSetupProtocol {
    private let _next: VideoSetupProtocol

    init(next: VideoSetupProtocol) {
        self._next = next
    }

    func next() -> VideoSetupProtocol {
        return _next
    }
    
    public func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        return self.next().video(video, kind: kind)
    }
    
    public func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        return self.next().data(data, kind: kind)
    }
    
    public func session(_ session: SessionProtocol, kind: Session.Kind) {
        return self.next().session(session, kind: kind)
    }
    
    public func complete() -> SessionProtocol? {
        return self.next().complete()
    }
}


open class VideoSetupVector : CaptureSetup.VectorBase<VideoSetupProtocol>, VideoSetupProtocol {
    public func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        return vector.reduce(video) { $1.video($0, kind: kind) }
    }
}


public func broadcast(_ x: [VideoSetupProtocol?]) -> VideoSetupProtocol? {
    broadcast(x, create: { VideoSetupVector($0) })
}


public class VideoSetupProcessor : VideoSetup {
    
    private let create: (VideoProcessor.Proto) -> VideoProcessor.Proto
    private let kind: VideoProcessor.Kind
    
    public convenience init(kind: VideoProcessor.Kind, video: VideoOutputProtocol) {
        self.init(kind: kind) { VideoProcessor(prev: video, next: $0) }
    }
    
    public init(kind: VideoProcessor.Kind, create: @escaping (VideoProcessor.Proto) -> VideoProcessor.Proto) {
        self.create = create
        self.kind = kind
    }
    
    public override func video(_ video: VideoOutputProtocol, kind: VideoProcessor.Kind) -> VideoOutputProtocol {
        var result = video
        
        if kind == self.kind {
            result = create(result)
        }
        
        return result
    }
}


public class VideoSetupDataProcessor : VideoSetup {
    
    private let data: DataProcessorProtocol
    private let kind: DataProcessor.Kind
    
    public init(data: DataProcessorProtocol, kind: DataProcessor.Kind) {
        self.data = data
        self.kind = kind
    }
    
    public override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
        var result = data
        
        if kind == self.kind {
            result = DataProcessor(prev: self.data, next: result)
        }
        
        return super.data(result, kind: kind)
    }
}


#if os(OSX)
public class VideoSetupCheckbox : VideoSetupChain {
    private let checkbox: NSButton
    
    public init(next: VideoSetupProtocol, checkbox: NSButton) {
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


public extension VideoSetup {
    class External: VideoSetupSlave {
        public private(set) var video: VideoProcessor.Proto = VideoProcessor.shared
        
        public override func session(_ session: Session.Proto, kind: Session.Kind) {
            if kind == .initial {
                let video = root.video(VideoProcessor.shared, kind: .capture)
                self.video = video
            }
        }
    }
}


public func cast(video session: Session.Setup) -> VideoSetupProtocol {
    return VideoSetupSessionAdapter(session)
}


public func cast(video capture: CaptureSetup.Proto) -> VideoSetupProtocol {
    return VideoSetupCaptureAdapter(capture)
}


public func cast(video data: DataProcessor.Setup) -> VideoSetupProtocol {
    return cast(video: cast(capture: data))
}
