//
//  AppKit.View.swift
//  spINFLUENCEit
//
//  Created by Ivan Kh on 04.06.2020.
//  Copyright © 2020 JoJo Systems. All rights reserved.
//

import AppKit

extension NSView {
    func descendants<T>(withClass: T.Type) -> [T] {
        var result = [T]()
        descendants(of: self, withClass: withClass, result: &result)
        return result
    }

    func descendants<T>(of view: NSView, withClass: T.Type, result: inout [T]) {
        for view in view.subviews {
            if let typedView = view as? T {
                result.append(typedView)
            }

            descendants(of: view, withClass: withClass, result: &result)
        }
    }
}
