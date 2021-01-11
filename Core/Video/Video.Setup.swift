//
//  Video.Setup.swift
//  Capture
//
//  Created by Ivan Kh on 17.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//


import AVFoundation
import AppKit


enum VideoSessionKind {
    case other
    case input
    case capture
    case avCapture
    case encoder
    case network
}


enum VideoOutputKind {
    case capture
    case duplicates
    case duplicatesFree
    case encoder
    case serializer
    case deserializer
    case preview
}


enum DataProcessorKind {
    case serializer
    case deserializer
    case network
    case networkData
}


protocol VideoSetupProtocol : class {
    func video(_ video: VideoOutputProtocol, kind: VideoOutputKind) -> VideoOutputProtocol
    func data(_ data: DataProcessor, kind: DataProcessorKind) -> DataProcessor
    func session(_ session: SessionProtocol, kind: VideoSessionKind)
    func complete() -> SessionProtocol?
}


class VideoSetup : VideoSetupProtocol {
    static let shared = VideoSetup()
    
    func complete() -> SessionProtocol? {
        return nil
    }
    
    func video(_ video: VideoOutputProtocol, kind: VideoOutputKind) -> VideoOutputProtocol {
        return video
    }

    func data(_ data: DataProcessor, kind: DataProcessorKind) -> DataProcessor {
        return data
    }

    func session(_ session: SessionProtocol, kind: VideoSessionKind) {
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


class VideoSetupGeneral : VideoSetupProtocol {
    private var sessions = [SessionProtocol]()
    
    func complete() -> SessionProtocol? {
        return broadcast(sessions)
    }
    
    func video(_ video: VideoOutputProtocol, kind: VideoOutputKind) -> VideoOutputProtocol {
        return video
    }

    func data(_ data: DataProcessor, kind: DataProcessorKind) -> DataProcessor {
        return data
    }

    func session(_ session: SessionProtocol, kind: VideoSessionKind) {
        sessions.append(session)
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
    
    func video(_ video: VideoOutputProtocol, kind: VideoOutputKind) -> VideoOutputProtocol {
        return self.next().video(video, kind: kind)
    }
    
    func data(_ data: DataProcessor, kind: DataProcessorKind) -> DataProcessor {
        return self.next().data(data, kind: kind)
    }
    func session(_ session: SessionProtocol, kind: VideoSessionKind) {
        return self.next().session(session, kind: kind)
    }
    
    func complete() -> SessionProtocol? {
        return self.next().complete()
    }
}


class VideoSetupVector : VideoSetupProtocol {
    private(set) var vector: [VideoSetupProtocol]
    
    init() {
        self.vector = []
        self.vector = self.create()
    }
    
    init(_ vector: [VideoSetupProtocol]) {
        self.vector = vector
    }
    
    func create() -> [VideoSetupProtocol] {
        return []
    }
    
    func video(_ video: VideoOutputProtocol, kind: VideoOutputKind) -> VideoOutputProtocol {
        return vector.reduce(video) { $1.video($0, kind: kind) }
    }
    
    func data(_ data: DataProcessor, kind: DataProcessorKind) -> DataProcessor {
        return vector.reduce(data) { $1.data($0, kind: kind) }
    }
    func session(_ session: SessionProtocol, kind: VideoSessionKind) {
        vector.forEach { $0.session(session, kind: kind) }
    }
    
    func complete() -> SessionProtocol? {
        return broadcast(vector.map { $0.complete() })
    }
}


func broadcast(_ x: [VideoSetupProtocol?]) -> VideoSetupProtocol? {
    broadcast(x, create: { VideoSetupVector($0) })
}


class VideoSetupProcessor : VideoSetup {
    
    private let video: VideoOutputProtocol
    private let kind: VideoOutputKind
    
    init(video: VideoOutputProtocol, kind: VideoOutputKind) {
        self.video = video
        self.kind = kind
    }
    
    override func video(_ video: VideoOutputProtocol, kind: VideoOutputKind) -> VideoOutputProtocol {
        var result = video
        
        if kind == self.kind {
            result = VideoOutputImpl(prev: self.video, next: result)
        }
        
        return result
    }
}


class VideoSetupDataProcessor : VideoSetup {
    
    private let data: DataProcessor
    private let kind: DataProcessorKind
    
    init(data: DataProcessor, kind: DataProcessorKind) {
        self.data = data
        self.kind = kind
    }
    
    override func data(_ data: DataProcessor, kind: DataProcessorKind) -> DataProcessor {
        var result = data
        
        if kind == self.kind {
            result = DataProcessorImpl(prev: self.data, next: result)
        }
        
        return result
    }
}


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

