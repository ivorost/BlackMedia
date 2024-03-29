//
//  Event.Capture.swift
//  Capture
//
//  Created by Ivan Kh on 23.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

#if canImport(AppKit)
import AppKit
#endif

public final class Event {
    public final class Setup {}
}


public class EventCapture {
    
}

#if canImport(AppKit)
extension EventCapture {
    class Monitor : Session.Proto {
        fileprivate let next: EventProcessor.AnyProto
        private var localMonitor: Any? = nil
        private var globalMonitor: Any? = nil

        init(next: EventProcessor.AnyProto) {
            self.next = next
        }
        
        func start() throws {
            let next = self.next

            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .any) {
                next.process($0)
                
                return $0.type == .keyUp || $0.type == .keyDown
                ? nil
                : $0
            }

//        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .any) { event in
//            next.process(_ event: event)
//        }
        }
        
        func stop() {
            if let localMonitor = localMonitor {
                NSEvent.removeMonitor(localMonitor)
            }
            
//        if let globalMonitor = globalMonitor {
//            NSEvent.removeMonitor(globalMonitor)
//        }
        }
    }
}
#endif

#if canImport(AppKit)
extension EventCapture {
    class Tap : Session.Proto {
        fileprivate let next: EventProcessor.AnyProto
        private var eventTap: CFMachPort?
        private var eventRunLoop: CFRunLoop?
        private var eventRunLoopSource: CFRunLoopSource?
        private var eventTapQueue: DispatchQueue?
        
        init(next: EventProcessor.AnyProto) {
            self.next = next
        }
        
        func start() throws {
            eventTapQueue = DispatchQueue.createEventsTap()
            
            eventTapQueue?.async {
                self.startTap()
                CFRunLoopRun()
            }
        }
        
        func stop() {
            stopTap()
            eventTapQueue = nil
        }
        
        private func startTap() {
            let eventMask =
                (1 << CGEventType.keyDown.rawValue) |
                (1 << CGEventType.keyUp.rawValue)
            
            eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                         place: .headInsertEventTap,
                                         options: .listenOnly,
                                         eventsOfInterest: CGEventMask(eventMask),
                                         callback: eventCallback,
                                         userInfo: unsafeBitCast(self, to: UnsafeMutableRawPointer.self))
            
            guard let eventTap = eventTap else { return }
            
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, CFIndex(0))
            let runLoop = CFRunLoopGetCurrent()
            
            self.eventRunLoop = runLoop
            self.eventRunLoopSource = runLoopSource
            
            CFRunLoopAddSource(runLoop, runLoopSource, CFRunLoopMode.commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
        
        private func stopTap() {
            if let eventRunLoop = eventRunLoop, let eventRunLoopSource = eventRunLoopSource {
                CFRunLoopRemoveSource(eventRunLoop, eventRunLoopSource, CFRunLoopMode.commonModes)
                CFRunLoopStop(eventRunLoop)
            }
            
            eventRunLoop = nil
            eventRunLoopSource = nil
        }
    }
}
#endif

#if canImport(AppKit)
fileprivate func eventCallback(proxy: CGEventTapProxy,
                               type: CGEventType,
                               event: CGEvent,
                               refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    let SELF: EventCapture.Tap = unsafeBitCast(refcon, to: EventCapture.Tap.self)
    
    if let nsEvent = NSEvent(cgEvent: event) {
        SELF.next.process(nsEvent)
    }
    else {
        assert(false)
    }

    return Unmanaged.passUnretained(event)
}
#endif


#if canImport(AppKit)
public extension EventCapture {
    class Setup : EventProcessorSetup.Slave {
        public override func session(_ session: Session.Proto, kind: Session.Kind) {
            if kind == .initial {
                let captureProcessor = root.event(EventProcessor.shared, kind: .capture)
                let captureTap = Session.shared// EventCapture.Tap(next: captureProcessor)
                
                let captureMonitorProcessor = EventProcessor.FilterByMaskNot(next: captureProcessor,
                                                                             notSupportedTypes: [ /*.keyUp, .keyDown*/ ])
                let captureMonitor = EventCapture.Monitor(next: captureMonitorProcessor)

                root.session(broadcast([captureTap, captureMonitor]), kind: .capture)
            }
        }
    }
}
#endif
