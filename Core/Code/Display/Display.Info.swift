//
//  Display.Info.swift
//  Capture
//
//  Created by Ivan Kh on 30.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation
#if os(OSX)
import AppKit
#endif

public extension DisplayCapture {
    class InfoCapture : PacketSerializer.Processor, Session.Proto {
        private let settings: DisplayConfig
        
        init(next: DataProcessor.Proto, settings: DisplayConfig) {
            self.settings = settings
            super.init(next: next)
        }
        
        public func start() throws {
            let packet = PacketSerializer(.display)
            packet.push(value: settings)
            
            print("display info")
            process(packet: packet)
        }
        
        public func stop() {
        }
    }
    
    
    class InfoViewer : PacketDeserializer.Processor {
        private(set) var settings: DisplayConfig?
        
        init() {
            super.init(type: .display)
        }

        override func process(packet: PacketDeserializer) {
            guard settings == nil else { return }
            var settings = DisplayConfig.zero
            
            packet.pop(&settings)
            self.settings = settings
        }
    }
    
    #if os(OSX)
    class AutosizeWindow : InfoViewer {
        private let window: NSWindow
        
        init(_ window: NSWindow) {
            self.window = window
        }
        
        override func process(packet: PacketDeserializer) {
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


public extension DisplaySetup {
    class InfoCapture : CaptureSetup.Slave {
        private let settings: DisplayConfig
        
        public init(root: CaptureSetup.Proto, settings: DisplayConfig) {
            self.settings = settings
            super.init(root: root)
        }

        public override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
            if kind == .networkData {
                let session = DisplayCapture.InfoCapture(next: data, settings: settings)
                root.session(session, kind: .other)
            }
            
            return super.data(data, kind: kind)
        }
    }
}


#if os(OSX)
public extension DisplaySetup {
    class AutosizeWindow : DataProcessorSetup.Default {
        public init(root: CaptureSetup.Proto, window: NSWindow) {
            super.init(root: root, targetKind: .networkDataOutput, selfKind: .other) {
                DataProcessor(prev: $0, next: DisplayCapture.AutosizeWindow(window))
            }
        }
    }
}
#endif
