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


public extension Video.Processor.Kind {
    static let capture = Video.Processor.Kind(rawValue: "capture")
    static let duplicatesFree = Video.Processor.Kind(rawValue: "duplicatesFree")
    static let duplicatesNext = Video.Processor.Kind(rawValue: "duplicatesNext")
    static let encoder = Video.Processor.Kind(rawValue: "encoder")
    static let decoder = Video.Processor.Kind(rawValue: "decoder")
    static let deserializer = Video.Processor.Kind(rawValue: "deserializer")
    static let preview = Video.Processor.Kind(rawValue: "preview")
}


public protocol VideoSetupProtocol : Capture.Setup.Proto {
    func video(_ video: Video.Processor.Proto, kind: Video.Processor.Kind) -> Video.Processor.Proto
}


public extension Video {
    final class Setup {
        public static let shared = Base()
    }
}


public extension Video.Setup {
    typealias Proto = VideoSetupProtocol
}


public extension Video.Setup {
    class Base : Proto {
        
        public init() {}
        
        public func complete() -> Session.Proto? {
            return nil
        }
        
        public func video(_ video: Video.Processor.Proto, kind: Video.Processor.Kind) -> Video.Processor.Proto {
            return video
        }

        public func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
            return data
        }

        public func session(_ session: Session.Proto, kind: Session.Kind) {
        }
    }
}


public extension Video.Setup {
    class Slave : Base {
        private(set) weak var _root: Proto?
        
        public init(root: Proto) {
            self._root = root
        }
        
        var root: Proto {
            return _root ?? Video.Setup.shared
        }
    }
}


public extension Video.Setup {
    class Chain : Proto {
        private let _next: Proto
        
        init(next: Proto) {
            self._next = next
        }
        
        func next() -> Proto {
            return _next
        }
        
        public func video(_ video: Video.Processor.Proto, kind: Video.Processor.Kind) -> Video.Processor.Proto {
            return self.next().video(video, kind: kind)
        }
        
        public func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
            return self.next().data(data, kind: kind)
        }
        
        public func session(_ session: Session.Proto, kind: Session.Kind) {
            return self.next().session(session, kind: kind)
        }
        
        public func complete() -> Session.Proto? {
            return self.next().complete()
        }
    }
}


extension Video.Setup {
    open class Vector : Core.Capture.Setup.VectorBase<Proto>, Proto {
        public func video(_ video: Video.Processor.Proto, kind: Video.Processor.Kind) -> Video.Processor.Proto {
            return vector.reduce(video) { $1.video($0, kind: kind) }
        }
    }
}


public extension Video.Setup {
    class Processor : Base {
        
        private let create: (Video.Processor.Proto) -> Video.Processor.Proto
        private let kind: Video.Processor.Kind
        
        public convenience init(kind: Video.Processor.Kind, video: Video.Processor.Proto) {
            self.init(kind: kind) { Video.Processor.Base(prev: video, next: $0) }
        }
        
        public init(kind: Video.Processor.Kind, create: @escaping (Video.Processor.Proto) -> Video.Processor.Proto) {
            self.create = create
            self.kind = kind
        }
        
        public override func video(_ video: Video.Processor.Proto, kind: Video.Processor.Kind) -> Video.Processor.Proto {
            var result = video
            
            if kind == self.kind {
                result = create(result)
            }
            
            return result
        }
    }
}

public extension Video.Setup {
    class DataProcessor : Base {
        
        private let data: Data.Processor.Proto
        private let kind: Data.Processor.Kind
        
        public init(data: Data.Processor.Proto, kind: Data.Processor.Kind) {
            self.data = data
            self.kind = kind
        }
        
        public override func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
            var result = data
            
            if kind == self.kind {
                result = Data.Processor.Base(prev: self.data, next: result)
            }
            
            return super.data(result, kind: kind)
        }
    }
}


#if os(OSX)
public extension Video.Setup {
    class Checkbox : Video.Setup.Chain {
        private let checkbox: NSButton
        
        public init(next: Proto, checkbox: NSButton) {
            self.checkbox = checkbox
            super.init(next: next)
        }
        
        override func next() -> Proto {
            return checkbox.state == .on
            ? super.next()
            : Video.Setup.shared
        }
    }
}
#endif


fileprivate extension Video.Setup {
    class SessionAdapter : Base {
        private let session: Session.Setup.Proto
        
        init(_ session: Session.Setup.Proto) {
            self.session = session
        }
        
        override func session(_ session: Session.Proto, kind: Session.Kind) {
            self.session.session(session, kind: kind)
        }
        
        override func complete() -> Session.Proto? {
            return self.session.complete()
        }
    }
}


fileprivate extension Video.Setup {
    class CaptureAdapter : SessionAdapter {
        private let capture: Core.Capture.Setup.Proto
        
        init(_ capture: Core.Capture.Setup.Proto) {
            self.capture = capture
            super.init(capture)
        }
        
        override func data(_ data: Data.Processor.Proto, kind: Data.Processor.Kind) -> Data.Processor.Proto {
            return capture.data(data, kind: kind)
        }
    }
}


public extension Video.Setup {
    class External: Slave {
        public private(set) var video: Video.Processor.Proto = Video.Processor.shared
        
        public override func session(_ session: Session.Proto, kind: Session.Kind) {
            if kind == .initial {
                let video = root.video(Video.Processor.shared, kind: .capture)
                self.video = video
            }
        }
    }
}


public func cast(video session: Session.Setup.Proto) -> Video.Setup.Proto {
    return Video.Setup.SessionAdapter(session)
}


public func cast(video capture: Capture.Setup.Proto) -> Video.Setup.Proto {
    return Video.Setup.CaptureAdapter(capture)
}


public func cast(video data: Data.Setup.Proto) -> Video.Setup.Proto {
    return cast(video: cast(capture: data))
}


public func broadcast(_ x: [Video.Setup.Proto?]) -> Video.Setup.Proto? {
    broadcast(x, create: { Video.Setup.Vector($0) })
}
