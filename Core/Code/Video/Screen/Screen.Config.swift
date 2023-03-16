//
//  Display.Info.swift
//  Capture
//
//  Created by Ivan Kh on 30.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AVFoundation
#if os(OSX)
import AppKit
#else
import UIKit
#endif


public extension Video {
    struct ScreenConfig : Equatable {
        public static let zero = ScreenConfig(displayID: 0, rect: CGRect.zero, scale: 0, fps: CMTime.zero)
        
        public let displayID: UInt32 // CGDirectDisplayID
        public let rect: CGRect
        public let scale: CGFloat
        public let fps: CMTime
        
        public init(displayID: UInt32, rect: CGRect, scale: CGFloat, fps: CMTime) {
            self.displayID = displayID
            self.rect = rect
            self.scale = scale
            self.fps = fps
        }
    }
}


public extension Video.ScreenConfig {
    init?(displayID: UInt32, fps: CMTime) {
        var rect = CGRect.zero
        var scale: CGFloat
        #if os(OSX)
        guard let displayMode = CGDisplayCopyDisplayMode(displayID) else { return nil }
        scale = CGFloat(displayMode.pixelWidth / displayMode.width)
        rect.size.width = CGFloat(displayMode.pixelWidth)
        rect.size.height = CGFloat(displayMode.pixelHeight)
        #else
        rect.size.width = UIScreen.main.bounds.width * UIScreen.main.scale
        rect.size.height = UIScreen.main.bounds.height * UIScreen.main.scale
        scale = UIScreen.main.scale
        #endif

        self.init(displayID: displayID, rect: rect, scale: scale, fps: fps)
    }
}

public extension Data.Processor {
    class ScreenConfigSerializer : Network.PacketSerializer.Processor, Session.Proto {
        private let settings: Video.ScreenConfig

        init(next: Data.Processor.AnyProto, settings: Video.ScreenConfig) {
            self.settings = settings
            super.init(next: next)
        }
        
        public func start() throws {
            let packet = Network.PacketSerializer(.display)
            packet.push(value: settings)
            
            print("display info")
            process(packet: packet)
        }
        
        public func stop() {
        }
    }
}


public extension Data.Processor {
    class ScreenConfigDeserializer : Network.PacketDeserializer.Processor {
        private(set) var settings: Video.ScreenConfig?
        
        init() {
            super.init(type: .display)
        }

        override func process(packet: Network.PacketDeserializer) {
            guard settings == nil else { return }
            var settings = Video.ScreenConfig.zero
            
            packet.pop(&settings)
            self.settings = settings
        }
    }
}


public extension Data.Processor {
    #if os(OSX)
    class AutosizeWindow : ScreenConfigDeserializer {
        private let window: NSWindow
        
        init(_ window: NSWindow) {
            self.window = window
        }
        
        override func process(packet: Network.PacketDeserializer) {
            super.process(packet: packet)
            
            if let settings = settings {
                var rect = CGRect.zero
                rect.origin.y = window.screen!.frame.size.height - rect.size.height
                rect.size = settings.rect.size
                
                rect.origin.x    /= settings.scale
                rect.origin.y    /= settings.scale
                rect.size.width  /= settings.scale
                rect.size.height /= settings.scale

                window.setFrame(rect, display: true, animate: true)
            }
        }
    }
    #endif
}


public extension Capture.Setup {
    class ScreenConfigSerializer : Slave {
        private let settings: Video.ScreenConfig
        
        public init(root: Proto, settings: Video.ScreenConfig) {
            self.settings = settings
            super.init(root: root)
        }

        public override func data(_ data: Data.Processor.AnyProto, kind: Data.Processor.Kind) -> Data.Processor.AnyProto {
            if kind == .networkData {
                let session = Data.Processor.ScreenConfigSerializer(next: data, settings: settings)
                root.session(session, kind: .other)
            }
            
            return super.data(data, kind: kind)
        }
    }
}


#if os(OSX)
public extension Data.Setup {
    class AutosizeWindow : Default {
        public init(root: Proto, window: NSWindow) {
            super.init(root: root, targetKind: .networkDataOutput, selfKind: .other) {
                Data.Processor.Base(prev: $0, next: Data.Processor.AutosizeWindow(window))
            }
        }
    }
}
#endif
