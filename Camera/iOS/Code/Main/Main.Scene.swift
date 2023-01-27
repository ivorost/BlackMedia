//
//  App.SwiftUI.swift
//  Camera
//
//  Created by Ivan Kh on 05.08.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import SwiftUI

struct Main {}

extension Main {
    @main
    struct Scene: App {
        @ObservedObject var vm = ViewModel()

        init() {
            let vm = vm

            Task {
                try! await vm.start()
            }
        }

        var body: some SwiftUI.Scene {
            WindowGroup {
                Select.View(vm: vm.select)
            }
        }
    }
}
