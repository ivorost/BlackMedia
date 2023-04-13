//
//  Foundation.Bundle.swift
//  Core
//
//  Created by Ivan Kh on 18.02.2021.
//

import Foundation

fileprivate class _BundleClass {}

extension Bundle {
    static let this: Bundle = Bundle(for: _BundleClass.self)
}
