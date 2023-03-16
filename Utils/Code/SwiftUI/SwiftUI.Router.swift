//
//  SwiftUI.Router.swift
//  Utils
//
//  Created by Ivan Kh on 07.04.2023.
//

import SwiftUI

public protocol RouterProtocol<Route>: ObservableObject {
    associatedtype Route
    associatedtype View: SwiftUI.View

    var route: Route { get }
    var routePublisher: Published<Route>.Publisher { get }
    @ViewBuilder var view: Self.View { get }
    func navigate(to route: Route)
}

public final class EmptyRouter<TRoute>: RouterProtocol {
    @Published public var route: TRoute
    public var routePublisher: Published<Route>.Publisher { $route }
    public var view: some View { EmptyView() }
    public func navigate(to route: TRoute) {}
    public init(_ route: TRoute) { self.route = route }
}

open class RouterToolbox<TRouter> {
    typealias Proto = RouterProtocol
    typealias AnyProto = any RouterProtocol<TRouter>
    typealias Empty = EmptyRouter<TRouter>
}
