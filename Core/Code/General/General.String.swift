//
//  Core.String.Processor.swift
//  Capture
//
//  Created by Ivan Kh on 18.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation
#if os(OSX)
import AppKit
#endif


public extension String {
    final class Processor: ProcessorToolbox<String> {}
}


public extension String {
    final class Producer: ProducerToolbox<String> {}
}


public extension String.Processor {
    static let shared: AnyProto = Base()
}


public extension String.Processor {
    class Base : ProcessorProtocol {
        public func process(_ string: String) {}
    }
}


public extension String.Processor {
    class Chain : Proto {
        let next: AnyProto?
        
        init(next: AnyProto?) {
            self.next = next
        }
        
        public func process(_ string: String) {
            next?.process(string)
        }
    }
}


public extension String.Processor {
    class ChainConstant : Chain {
        let prepend: String
        
        public init(prepend: String, next: AnyProto?) {
            self.prepend = prepend
            super.init(next: next)
        }
        
        public override func process(_ string: String) {
            super.process(prepend + string)
        }
    }
}


public extension String.Processor {
    class FlushLast : Chain, Flushable.Proto {
        private var string: String?
        
        public init(_ next: AnyProto?) {
            super.init(next: next)
        }
        
        public override func process(_ string: String) {
            self.string = string
        }
        
        public func flush() {
            if let string = string {
                super.process(string)
            }
        }
    }
}


public extension String.Processor {
    class FlushAll : Chain, Flushable.Proto {
        var strings = [String]()
        let lock = NSLock()
        
        init(_ next: AnyProto?) {
            super.init(next: next)
        }

        public override func process(_ string: String) {
            lock.locked { strings.append(string) }
        }
        
        public func flush() {
            var joined = ""
            
            lock.locked {
                joined = strings.joined(separator: "\n")
                strings.removeAll()
            }
            
            super.process(joined)
        }
    }
}


public extension String.Processor {
    final class Print : ProcessorProtocol {
        public typealias Value = String
        public static let shared = Print()
        private let title: String
        
        public init(_ title: String = "") {
            self.title = title
        }
        
        public func process(_ string: String) {
            print("\(title)\(string)")
        }
    }
}

#if os(OSX)
public extension String.Processor {
    class TableView : Chain {
        private let tableView: NSTableView
        private let arrayController = NSArrayController()
        private var lastScrollPosition: CGPoint?
        
        public init(tableView: NSTableView, next: String.Processor.Proto? = nil) {
            self.tableView = tableView
            super.init(next: next)
            
            tableView.bind(.content,
                           to: arrayController,
                           withKeyPath: "arrangedObjects",
                           options: nil)
        }
        
        public override func process(string: String) {
            super.process(string: string)
            
            dispatchMainAsync {
                let strings = string.split(separator: "\n")
                
                self.tableView.beginUpdates()
                
                for string in strings {
                    self.arrayController.addObject(string)
                }
                
                self.tableView.endUpdates()
                self.tableView.scrollToEndOfDocument(nil)
            }
        }
    }
}
#endif
