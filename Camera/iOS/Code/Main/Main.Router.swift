//
//  Main.Router.swift
//  Camera
//
//  Created by Ivan Kh on 07.04.2023.
//  Copyright © 2023 Ivan Kh. All rights reserved.
//

import SwiftUI
import Utils

extension Main {
    final class Router {}
}

extension Main.Router {
    enum Route {
        case pair
        case scan
        case role
        case stream
    }
}

extension Main.Router {
    typealias Proto = RouterProtocol
    typealias AnyProto = any RouterProtocol<Route>
    typealias Empty = EmptyRouter<Route>
}

extension Main.Router {
    class General: Proto {
        @Published var route: Route = .pair
        var routePublisher: Published<Route>.Publisher { $route }
        private var animateAppearance = false

        var view: some View {
            switch route {
            case .pair:
                Peer.PairView(router: self, animateAppearance: animateAppearance)
                    .animationModifier()
            case .scan:
                Peer.ScanView(router: self, animateAppearance: animateAppearance)
                    .animationModifier()
            case .role:
                EmptyView()
            case .stream:
                EmptyView()
            }
        }

        func navigate(to route: Route) {
            animateAppearance = true
            self.route = route
        }
    }
}

private extension View {
    func animationModifier() -> some View {
        let duration: CFTimeInterval = 0.5

        return self
            .transition(.asymmetric(insertion: .dummy, removal: .dummy).animation(.linear(duration: duration)))
            .environment(\.animationDuration, duration)
    }
}
