//
//  Event.Post.swift
//  Capture
//
//  Created by Ivan Kh on 25.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

#if canImport(AppKit)
import AppKit
#endif
import BlackUtils

#if canImport(AppKit)
public extension EventProcessor {
    class Post : Chain {
        public override func process(_ event: NSEvent) {
            dispatchMainAsync {
                event.cgEvent?.post(tap: .cghidEventTap)
            }
            super.process(event)
        }
    }
}
#endif


#if canImport(AppKit)
public extension EventProcessorSetup {
    class Post : Default {
        public init(root: Proto) {
            super.init(root: root,
                       targetKind: .deserializer,
                       selfKind: .post,
                       create: { return EventProcessor.Post(next: $0) })
        }
    }
}
#endif

#if canImport(AppKit)
public extension EventProcessor.Post {
    typealias Setup = EventProcessorSetup.Post
}
#endif
