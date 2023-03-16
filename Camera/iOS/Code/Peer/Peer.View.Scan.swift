//
//  Peer.View.Scan.swift
//  Camera
//
//  Created by Ivan Kh on 29.03.2023.
//  Copyright © 2023 Ivan Kh. All rights reserved.
//

import SwiftUI

extension Peer {
    struct ScanView<TRouter: Main.Router.Proto>: SwiftUI.View
    where TRouter.Route == Main.Router.Route {
        let router: TRouter
        let animateAppearance: Bool
        @State private var session: Session.Proto = Session.shared

        var body: some SwiftUI.View {
            BaseView(router: router,
                     route: .scan,
                     master: master(g:),
                     button: button,
                     animateAppearance: animateAppearance)
        }

        func master(g: GeometryProxy) -> some View {
            let sampleBufferView = SampleBufferDisplaySwiftUI()

            return sampleBufferView
                .videoGravity(.resizeAspectFill)
                .ignoresSafeArea()
                .background(Color.black.opacity(0.5))
                .onAppear {
                    let string = String.Processor.Vibrate().asProducer()
                        .next(String.Processor.Print.shared)
                        .next(String.Processor.PeerIdentity { identity in
                            session.stop()
                            print(identity)
                        })
                        .first
                    let video = Video.Processor.Display(sampleBufferView.layer)

                    session = Video.scanQR(video: video, string: string)

                    DispatchQueue.global().async {
                        tryLog {
                            try session.start()
                        }
                    }
                }
                .onDisappear {
                    session.stop()
                }
        }

        var button: some View {
            Button(action: {
                router.navigate(to: .pair)
            }) {
                ZStack {
                    Image("peer_stop")
                    Text("Stop")
                        .foregroundColor(.black)
                        .opacity(0.8)
                }
            }
        }
    }
}

struct PeerScanPreview: PreviewProvider {
    static var previews: some View {
        Peer.ScanView(router: Main.Router.Empty(.pair), animateAppearance: false)
    }
}

fileprivate extension String.Processor {
    class PeerIdentity: Proto {
        private let callback: (Network.Peer.Identity) -> Void

        init(_ callback: @escaping (Network.Peer.Identity) -> Void) {
            self.callback = callback
        }

        func process(_ value: String) {
            guard let identity = tryLog({ try Network.Peer.Identity(base64: value) }) else { return }
            callback(identity)
        }
    }
}
