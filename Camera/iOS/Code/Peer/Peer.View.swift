//
//  Peer.View.swift
//  Camera
//
//  Created by Ivan Kh on 07.04.2023.
//  Copyright © 2023 Ivan Kh. All rights reserved.
//

import SwiftUI
import CoreGraphics
import Utils

extension Peer {
    struct BaseView<TRouter: Main.Router.Proto, TMaster: View, TButton: View>: View
    where TRouter.Route == Main.Router.Route {
        @ObservedObject var router: TRouter
        let route: Main.Router.Route
        let master: (GeometryProxy) -> TMaster
        let button: TButton
        let animateAppearance: Bool

        @Environment(\.animationDuration) var animationDuration: CFTimeInterval
        @State private var showMaster = false
        @State private var showHelper = true
        @State private var appearanceCompleted = false

        var body: some View {
            GeometryReader { g in
                VStack(spacing: 0) {
                    ZStack {
                        master(g)
                    }
                    .frame(height: g.size.height * 2 / 3)
                    .background(Color.applicationBackground)
                    .curtains(removal: router.route != route, duration: animationDuration)
                    .opacity(showMaster ? 1 : 0)

                    ZStack {
                        VStack(spacing: 0) {
                            Divider()
                                .background(Color.black)
                                .shadow(color: .black, radius: 3, y: 0)

                            Spacer()

                            button
                                .disabled(router.route != route || !appearanceCompleted)

                            Spacer()
                                .frame(height: 40)

                            Text("To pair please scan QR code from the second device")
                                .padding([.leading, .trailing], 30)
                                .multilineTextAlignment(.center)

                            Spacer()
                        }
                    }
                    .clipped()
                    .frame(height: g.size.height * 1 / 3)
                    .frame(maxWidth: .infinity)
                    .background(Color("peer_scan_bg"))
                    .opacity(showHelper ? 1 : 0)
                }
                .background(.clear)
            }
            .onAppear() {
                if animateAppearance {
                    withAnimation(.linear(duration: animationDuration).delay(0.1)) {
                        showMaster = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.2) {
                        appearanceCompleted = true
                    }
                }
                else {
                    showMaster = true
                    appearanceCompleted = true
                }
            }
            .onReceive(router.routePublisher) { newValue in
                if newValue != route {
                    withAnimation(.linear(duration: animationDuration)) {
                        showHelper = false
                    }
                }
            }
        }
    }
}

struct Peer_View_Previews: PreviewProvider {
    static var previews: some View {
        Peer.BaseView(router: Main.Router.Empty(.pair),
                      route: .pair,
                      master: { _ in Color.black },
                      button: Button("", action: {}),
                      animateAppearance: false)
    }
}
