//
//  Core.Viewer.swift
//  Application-macOS
//
//  Created by Ivan Kh on 16.02.2021.
//

import Foundation

class Viewer : VideoSetupVector {
    private let url: URL
    private let view: SampleBufferDisplayView
    private(set) var reader: VideoSetup.AssetReader?
    
    init(url: URL, view: SampleBufferDisplayView) {
        self.url = url
        self.view = view
        super.init()
    }

    override func create() -> [VideoSetupProtocol] {
        let root = self
        let reader = VideoSetup.AssetReader(url: url, root: root)
        let preview = VideoSetupPreview(root: root, layer: view.sampleLayer, kind: .decoder)
        let decoder = VideoProcessor.DecoderH264.Setup(root: root, target: .capture)
        let aggregator = SessionSetup.Aggregator()

        self.reader = reader
        
        return [
            cast(video: aggregator),
            reader,
            decoder,
            preview ]
    }
}
