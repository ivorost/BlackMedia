//
//  SwiftUI.Transition.Dummy.swift
//  Utils
//
//  Created by Ivan Kh on 11.04.2023.
//

import SwiftUI

private struct DummyShape: Shape {
    var animatableData: Double

    func path(in rect: CGRect) -> Path {
        return Rectangle().path(in: rect)
    }
}

private struct DummyShapeModifier<T: Shape>: ViewModifier {
    let shape: T

    func body(content: Content) -> some View {
        content.clipShape(shape)
    }
}

public extension AnyTransition {
    static var dummy: AnyTransition {
        .modifier(
            active: DummyShapeModifier(shape: DummyShape(animatableData: 0)),
            identity: DummyShapeModifier(shape: DummyShape(animatableData: 1))
        )
    }
}


