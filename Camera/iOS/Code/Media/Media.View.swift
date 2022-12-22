//
//  Media.Get.View.swift
//  Camera
//
//  Created by Ivan Kh on 04.11.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import SwiftUI
import Utils

extension Media {
    struct View: SwiftUI.View {
        @ObservedObject var vm: ViewModel

        var body: some SwiftUI.View {
            let sampleBufferView = SampleBufferDisplaySwiftUI()

            sampleBufferView
                .onAppear {
                    vm.start(layer: sampleBufferView.layer)
                }
                .onDisappear {
                    vm.stop()
                }
        }
    }
}


struct MediaViewPreview: PreviewProvider {
    static var previews: some View {
        Media.View(vm: Media.ViewModel())
    }
}
