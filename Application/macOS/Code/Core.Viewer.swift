//
//  Core.Viewer.swift
//  Application-macOS
//
//  Created by Ivan Kh on 16.02.2021.
//

import Foundation


fileprivate extension Double {
    static var fps = 60.0
}


class Viewer : VideoSetupVector {
    typealias Info = (url: URL, view: SampleBufferDisplayView)
    
    private let info: [Info]
    private(set) var readers = [VideoSetup.AssetReader]()
    
    init(_ info: [Info]) {
        self.info = info
        super.init()
    }
    
    override func create() -> [VideoSetupProtocol] {
        var result = [VideoSetupProtocol]()
        var flushables = [Flushable.Proto]()
        let root = self

        for i in info {
            let reader = VideoSetup.AssetReader(url: i.url, root: root)
            let preview = VideoSetupPreview(root: root, layer: i.view.sampleLayer, kind: .decoder)
            
            result.append(reader)
            result.append(preview)
            flushables.append(reader.flushable)
            readers.append(reader)
        }
        
        let decoder = VideoProcessor.DecoderH264.Setup(root: root, target: .capture)
        let aggregator = SessionSetup.Background(next: SessionSetup.Aggregator(),
                                                 thread: BackgroundThread(Viewer.self))
        let timer = Flushable.Periodically(interval: 1.0 / .fps, next: Flushable.Vector(flushables))
//        let recolor = VideoSetup.Recolor(target: .decoder)

        result.append(cast(video: aggregator))
        result.append(cast(video: SessionSetup.Static(root: root, session: timer)))
        result.append(decoder)
//        result.append(recolor)
        
        return result
    }
}
