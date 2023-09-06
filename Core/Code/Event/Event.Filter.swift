//
//  Event.Filter.swift
//  Capture
//
//  Created by Ivan Kh on 03.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//



#if canImport(AppKit)
import AppKit
#endif


public extension EventProcessor {
    class FilterByMask : Chain {
        fileprivate let supportedTypes: NSEvent.EventTypeMask
        
        public init(next: EventProcessor.Proto, supportedTypes: NSEvent.EventTypeMask) {
            self.supportedTypes = supportedTypes
            super.init(next: next)
        }
        
        public override func process(event: NSEvent) {
            if shouldProcess(event) {
                super.process(event: event)
            }
        }
        
        fileprivate func shouldProcess(_ event: NSEvent) -> Bool {
            return supportedTypes.contains(NSEvent.EventTypeMask(type: event.type))
        }
    }
    
    class FilterByMaskNot : FilterByMask {
        public init(next: EventProcessor.Proto, notSupportedTypes: NSEvent.EventTypeMask) {
            super.init(next: next, supportedTypes: notSupportedTypes)
        }
        
        public override func shouldProcess(_ event: NSEvent) -> Bool {
            return !super.shouldProcess(event)
        }
    }
}


public extension EventProcessorSetup {
    class FilterByMask : Default {
        public init(root: EventProcessor.Setup, supportedTypes: NSEvent.EventTypeMask) {
            super.init(root: root, targetKind: .capture, selfKind: .filterTypes) {
                return EventProcessor.FilterByMask(next: $0, supportedTypes: supportedTypes)
            }
        }
    }
}


public extension EventProcessor.FilterByMask {
    typealias Setup = EventProcessorSetup.FilterByMask
}


public extension EventProcessor {
    class FilterByWindow : Chain {
        private let window: NSWindow
        private let windowNumber: Int
        
        public init(next: EventProcessor.Proto, window: NSWindow) {
            self.window = window
            self.windowNumber = window.windowNumber
            super.init(next: next)
        }
        
        public override func process(event: NSEvent) {
            let windowNumber = NSWindow.windowNumber(at: NSEvent.mouseLocation, belowWindowWithWindowNumber: 0)
            guard self.windowNumber == windowNumber else { return }
            
            super.process(event: event)
        }
    }
}


public extension EventProcessorSetup {
    class FilterByWindow : Default {
        public init(root: EventProcessor.Setup, window: NSWindow) {
            super.init(root: root, targetKind: .capture, selfKind: .filterWindow) {
                return EventProcessor.FilterByWindow(next: $0, window: window)
            }
        }
    }
}


public extension EventProcessor.FilterByWindow {
    typealias Setup = EventProcessorSetup.FilterByWindow
}


extension EventProcessor {
    class FilterByTimer : Chain, Session.Proto {
        private var timer: Timer?
        private let interval: TimeInterval
        private var event: NSEvent?
        
        init(next: Proto, interval: TimeInterval) {
            self.interval = interval
            super.init(next: next)
        }
        
        func start() throws {
            timer = Timer.scheduledTimer(timeInterval: interval,
                                         target: self,
                                         selector: #selector(flush),
                                         userInfo: nil,
                                         repeats: true)
        }
        
        func stop() {
            timer?.invalidate()
        }
        
        override func process(event: NSEvent) {
            self.event = event
        }
        
        @objc fileprivate func flush() {
            guard let event = event else { return }
            
            super.process(event: event)
            self.event = nil
        }
    }
}


extension EventProcessor.FilterByTimer {
    class Flush : EventProcessor.Chain {
        private let timer: EventProcessor.FilterByTimer
        
        init(next: EventProcessor.Proto, timer: EventProcessor.FilterByTimer) {
            self.timer = timer
            super.init(next: next)
        }

        override func process(event: NSEvent) {
            timer.flush()
            super.process(event: event)
        }
    }
}


public extension EventProcessorSetup {
    class FilterMouseMove : Slave {
        private let interval: TimeInterval
        private let queue: DispatchQueue
        
        public init(root: EventProcessor.Setup, queue: DispatchQueue, interval: TimeInterval) {
            self.interval = interval
            self.queue = queue
            super.init(root: root)
        }
        
        public override func event(_ event: EventProcessor.Proto, kind: EventProcessor.Kind) -> EventProcessor.Proto {
            var result = event
            
            if kind == .capture {
                let dispatch = EventProcessor.DispatchAsync(next: result, queue: queue)
                let filterByTimer = EventProcessor.FilterByTimer(next: dispatch, interval: interval)
                let filterMouseMove = EventProcessor.FilterByMask(next: filterByTimer, supportedTypes: [.mouseMoved])
                let filterByTimerFlush = EventProcessor.FilterByTimer.Flush(next: result, timer: filterByTimer)
                let filterNotMouseMove = EventProcessor.FilterByMaskNot(next: filterByTimerFlush,
                                                                        notSupportedTypes: [.mouseMoved])
                
                result = EventProcessor.Chain(prev: filterMouseMove, next: filterNotMouseMove)
                root.session(Session.DispatchSync(session: filterByTimer, queue: DispatchQueue.main), kind: .other)
            }
            
            return super.event(result, kind: kind)
        }
    }
}
