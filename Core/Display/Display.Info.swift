//
//  Display.Info.swift
//  Capture
//
//  Created by Ivan Kh on 30.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AppKit


extension DisplayCapture {
    class InfoCapture : Session {
        private let network: DataProcessor.Proto
        private let settings: DisplayConfig
        
        init(network: DataProcessor.Proto, settings: DisplayConfig) {
            var rect = settings.rect
            rect.size.width /= NSScreen.main?.backingScaleFactor ?? 1.0
            rect.size.height /= NSScreen.main?.backingScaleFactor ?? 1.0

            let settingsVar = DisplayConfig(displayID: settings.displayID,
                                            rect: rect,
                                            fps: settings.fps)
            

            self.network = network
            self.settings = settingsVar
            super.init()
        }
        
        override func start() throws {
            let packet = PacketSerializer(.display)
            packet.push(value: settings)
            
            network.process(data: packet.data)
            try super.start()
        }
    }
    
    class InfoViewer : DataProcessor {
        private(set) var settings: DisplayConfig?
        
        override func process(data: Data) {
            super.process(data: data)

            guard settings == nil else { return }
            let packet = PacketDeserializer(data)
            var settings = DisplayConfig.zero
            
            guard packet.type == .display else { return }
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
                let session = DisplayCapture.InfoCapture(network: data, settings: settings)
                root.session(session, kind: .other)
            }
            
            return super.data(data, kind: kind)
        }
    }
}
