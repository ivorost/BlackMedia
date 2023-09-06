//
//  AppKit.View.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 04.06.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

public extension AppleView {
    func addSubview(filling subview: AppleView) {
        #if canImport(UIKit)
        insetsLayoutMarginsFromSafeArea = false
        subview.insetsLayoutMarginsFromSafeArea = false
        #endif

        subview.translatesAutoresizingMaskIntoConstraints = true

        #if canImport(UIKit)
        subview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        #endif

        #if canImport(AppKit)
        subview.autoresizingMask = [.width, .height]
        #endif

        addSubview(subview)
    }

    func firstAncestor<T>() -> T? {
        var current = self

        while current.superview != nil {
            if let ancestor = current.superview as? T {
                return ancestor
            }

            if let superview = current.superview {
                current = superview
            }
        }

        return nil
    }

    func firstDescendant<T>() -> T? {
        return descendants(withClass: T.self).first
    }

    func descendants<T>(withClass: T.Type) -> [T] {
        var result = [T]()
        descendants(of: self, withClass: withClass, result: &result)
        return result
    }

    func descendants<T>(of view: AppleView, withClass: T.Type, result: inout [T]) {
        for view in view.subviews {
            if let typedView = view as? T {
                result.append(typedView)
            }

            descendants(of: view, withClass: withClass, result: &result)
        }
    }
}
