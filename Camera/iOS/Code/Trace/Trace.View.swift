//
//  Trace.View.swift
//  Camera
//
//  Created by Ivan Kh on 05.08.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import SwiftUI

struct Trace {}


extension Trace {
    struct View: SwiftUI.View {
        @ObservedObject var vm: ViewModel
        
        var body: some SwiftUI.View {
            VStack {
                List {
                    Section(header: Text("Peers")) {
                        ForEach(vm.peers, id: \.id) { peer in
                            Text(peer.name)
                        }
                    }

                    Section(header: Text("Log")) {
                        ForEach(vm.logs.indices, id: \.self) { idx in
                            Text(vm.logs[idx].description)
                        }
                    }
                }
            }
        }
    }
}


struct TracePreview: PreviewProvider {
    static var previews: some View {
        Trace.View(vm: .init())
    }
}
