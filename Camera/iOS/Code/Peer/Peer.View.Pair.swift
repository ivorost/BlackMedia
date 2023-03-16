//
//  Peer.View.swift
//  Camera
//
//  Created by Ivan Kh on 29.03.2023.
//  Copyright © 2023 Ivan Kh. All rights reserved.
//

import SwiftUI
import QRCode
import Core

extension Peer {
    struct PairView<TRouter: Main.Router.Proto>: SwiftUI.View
    where TRouter.Route == Main.Router.Route {
        let router: TRouter
        let animateAppearance: Bool

        var body: some SwiftUI.View {
            BaseView(router: router,
                     route: .pair,
                     master: master(g:),
                     button: button,
                     animateAppearance: animateAppearance)
        }

        func master(g: GeometryProxy) -> some View {
            QRImage(size: g.size.width - 100)
                .padding([.all], 50)
        }

        var button: some View {
            Button(action: {
                router.navigate(to: .scan)
            }) {
                ZStack {
                    Image("peer_scan")
                    Text("Scan")
                        .foregroundColor(.black)
                        .opacity(0.8)
                }
            }
        }
    }
}

struct PeerViewPreview: PreviewProvider {
    static var previews: some View {
        Peer.PairView(router: Main.Router.Empty(.pair), animateAppearance: false)
    }
}

extension Peer.PairView {
    enum Error: Swift.Error {
        case qrGenerationFailed(String)
    }
}

extension Peer.PairView {
    func QRImage(size: CGFloat) -> AnyView {
        let string = "Hacking with Swift is the best iOS coding tutorial I've ever read!"

        guard let cgImage = generateQR(string: string, size: size) else {
            logError(Error.qrGenerationFailed(string))
            return AnyView(EmptyView())
        }

        let result = Image(cgImage, scale: 1, label: Text(""))
            .resizable()
            .aspectRatio(contentMode: .fit)

        return AnyView(result)
    }

    private func generateQR(string: String, size: CGFloat) -> CGImage? {
        guard let base64 = tryLog({ try Network.Peer.Identity.wifi.qrBase64() }) else { return nil }
        let scaledSize = size * UIScreen.main.scale
        let doc2 = QRCode.Document(utf8String: base64)
        doc2.design.backgroundColor(UIColor.clear.cgColor)
        doc2.design.shape.eye = QRCode.EyeShape.RoundedOuter()
        doc2.design.shape.onPixels = QRCode.PixelShape.Circle()
        doc2.design.style.onPixels = QRCode.FillStyle.Solid(UIColor.systemBrown.cgColor)

        // Eye color
        doc2.design.style.eye = QRCode.FillStyle.Solid(UIColor.systemBrown.cgColor)
        // Pupil color
        doc2.design.style.pupil = QRCode.FillStyle.Solid(UIColor.systemBrown.cgColor)
        // Data color
        doc2.design.style.onPixels = QRCode.FillStyle.Solid(UIColor.systemBrown.cgColor)

        // Generate a image for the QRCode
        return doc2.cgImage(CGSize(width: scaledSize, height: scaledSize))
    }
}
