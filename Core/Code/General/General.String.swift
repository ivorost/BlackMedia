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


public protocol StringProcessorProtocol {
    func process(string: String)
}


public extension String {
    final class Processor {}
}


public extension String.Processor {
    static let shared: String.Processor.Proto = Base()
}

public extension String.Processor {
    typealias Proto = StringProcessorProtocol
}


public extension String.Processor {
    class Base : Proto {
        public func process(string: String) {}
    }
}


public extension String.Processor {
    class Chain : Proto {
        let next: Proto?
        
        init(next: Proto?) {
            self.next = next
        }
        
        public func process(string: String) {
            next?.process(string: string)
        }
    }
}


public extension String.Processor {
    class ChainConstant : Chain {
        let prepend: String
        
        public init(prepend: String, next: Proto?) {
            self.prepend = prepend
            super.init(next: next)
        }
        
        public override func process(string: String) {
            super.process(string: prepend + string)
        }
    }
}


public extension String.Processor {
    class FlushLast : Chain, Flushable.Proto {
        private var string: String?
        
        public init(_ next: String.Processor.Proto?) {
            super.init(next: next)
        }
        
        public override func process(string: String) {
            self.string = string
        }
        
        public func flush() {
            if let string = string {
                super.process(string: string)
            }
        }
    }
}


public extension String.Processor {
    class FlushAll : Chain, Flushable.Proto {
        var strings = [String]()
        let lock = NSLock()
        
        init(_ next: String.Processor.Proto?) {
            super.init(next: next)
        }

        public override func process(string: String) {
            lock.locked { strings.append(string) }
        }
        
        public func flush() {
            var joined = ""
            
            lock.locked {
                joined = strings.joined(separator: "\n")
                strings.removeAll()
            }
            
            super.process(string: joined)
        }
    }
}


public extension String.Processor {
    final class Print : Proto {
        public static let shared = Print()
        
        public func process(string: String) {
            print(string)
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
