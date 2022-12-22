//
//  Select.View.swift
//  Camera
//
//  Created by Ivan Kh on 05.08.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import SwiftUI


struct Select {}


extension Select {
    struct View: SwiftUI.View {
        @ObservedObject var vm: ViewModel

        var body: some SwiftUI.View {
            NavigationView {
                content
                    .navigationBarTitle("Who will be here?", displayMode: .inline)
                    .navigationBarItems(
                        trailing:
                            NavigationLink(destination: Trace.View(vm: vm.trace)) {
                                Text("Trace")
                            }
                    )
            }
            .navigationViewStyle(.stack)
        }

        @ViewBuilder
        private var content: some SwiftUI.View {
            VStack {
                Spacer()
                
                NavigationLink(destination: Media.View(vm: Media.Put.ViewModel(vm.selector))) {
                    Image("baby")
                }
                
                Spacer()
                Text("- or -")
                Spacer()
                
                NavigationLink(destination: Media.View(vm: Media.Get.ViewModel(vm.selector))) {
                    Image("parents")
                }
                
                Spacer()
            }
            .frame(maxHeight: .infinity)
        }
    }
}


struct SelectPreview: PreviewProvider {
    static var previews: some SwiftUI.View {
        Select.View(vm: .init())
    }
}
