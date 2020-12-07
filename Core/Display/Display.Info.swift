//
//  Display.Info.swift
//  Capture
//
//  Created by Ivan Kh on 30.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AppKit


extension DisplayCapture {
    class InfoCapture : PacketSerializer.Processor, Session.Proto {
        private let settings: DisplayConfig
        
        init(next: DataProcessor.Proto, settings: DisplayConfig) {
            var rect = settings.rect
            rect.size.width /= NSScreen.main?.backingScaleFactor ?? 1.0
            rect.size.height /= NSScreen.main?.backingScaleFactor ?? 1.0

            let settingsVar = DisplayConfig(displayID: settings.displayID,
                                            rect: rect,
                                            fps: settings.fps)
            

            self.settings = settingsVar
            super.init(next: next)
        }
        
        func start() throws {
            let packet = PacketSerializer(.display)
            packet.push(value: settings)
            
            process(packet: packet)
        }
        
        func stop() {
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
}


extension DisplaySetup {
    class InfoCapture : CaptureSetup.Slave {
        private let settings: DisplayConfig
        
        init(root: CaptureSetup.Proto, settings: DisplayConfig) {
            self.settings = settings
            super.init(root: root)
        }

        override func data(_ data: DataProcessorProtocol, kind: DataProcessor.Kind) -> DataProcessorProtocol {
            if kind == .networkData {
                let session = DisplayCapture.InfoCapture(next: data, settings: settings)
                root.session(session, kind: .other)
            }
            
            return super.data(data, kind: kind)
        }
    }
}
