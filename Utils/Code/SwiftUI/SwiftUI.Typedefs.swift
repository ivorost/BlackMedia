//
//  File.swift
//  
//
//  Created by Ivan Kh on 13.04.2023.
//

import SwiftUI

#if canImport(UIKit)
typealias AppleViewRepresentable = UIViewRepresentable
typealias AppleHostingController = UIHostingController
#endif

#if canImport(AppKit)
typealias AppleViewRepresentable = NSViewRepresentable
typealias AppleHostingController = NSHostingController
#endif
