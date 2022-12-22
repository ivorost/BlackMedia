//
//  SwiftUI.SampleBuffer.swift
//  Utils-macOS
//
//  Created by Ivan Kh on 04.11.2022.
//


#if os(iOS)
import SwiftUI
import UIKit


public struct SampleBufferDisplaySwiftUI: UIViewRepresentable {

    @State private(set) var view = SampleBufferDisplayView()

    public init() {
    }
    
    public var layer: SampleBufferDisplayLayer {
        view.sampleLayer
    }

    public func makeUIView(context: Context) -> UIView {
        view
    }

    public func updateUIView(_ uiView: UIView, context: Context) { }
}
#endif
