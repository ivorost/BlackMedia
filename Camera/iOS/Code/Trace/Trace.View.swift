//
//  Trace.View.swift
//  Camera
//
//  Created by Ivan Kh on 05.08.2022.
//  Copyright © 2022 Ivan Kh. All rights reserved.
//

import SwiftUI
import Core

struct Trace {}


extension Trace {
    struct View: SwiftUI.View {
        @ObservedObject var vm: ViewModel
        
        var body: some SwiftUI.View {
            VStack {
                List {
                    Section(header: Text("Peers")) {
                        ForEach(vm.peers, id: \.id) { peer in
                            Peer(peer: .init(peer))
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

extension Trace.View {
    struct Peer : SwiftUI.View {
        @StateObject var peer: Network.Peer.StateObservable

        var body: some SwiftUI.View {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(Color(peer.state.value.color))

                    Text(peer.name)
                }

                Divider()
                    .opacity(0.5)

                HStack {
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(.clear)

                    #if DEBUG
                    Text(peer.debugDescription.value)
                    #endif
                }
            }
        }
    }
}

extension Network.Peer.State {
    var color: UIColor {
        switch self {
        case .connected: return .green
        case .available, .connecting: return .yellow
        case .disconnected, .disconnecting, .unavailable: return .red
        }
    }
}

struct TracePreview: PreviewProvider {
    static var previews: some View {
        Trace.View(vm: .init())
    }
}
