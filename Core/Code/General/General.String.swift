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

public protocol StringProcessorProto {
    func process(string: String)
}


public class StringProcessorBase : StringProcessorProto {
    public func process(string: String) {}
}


public class StringProcessor : StringProcessorBase {
    public static let shared = StringProcessor()
}


public extension StringProcessor {
    typealias Base = StringProcessorBase
    typealias Proto = StringProcessorProto
}


public extension StringProcessor {
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


public extension StringProcessor {
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


public extension StringProcessor {
    class FlushLast : Chain, Flushable.Proto {
        private var string: String?
        
        public init(_ next: StringProcessor.Proto?) {
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


public extension StringProcessor {
    class FlushAll : Chain, Flushable.Proto {
        var strings = [String]()
        let lock = NSLock()
        
        init(_ next: StringProcessor.Proto?) {
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


public extension StringProcessor {
    final class Print : Base {
        public static let shared = Print()
        
        public override func process(string: String) {
            print(string)
        }
    }
}

#if os(OSX)
public extension StringProcessor {
    class TableView : Chain {
        private let tableView: NSTableView
        private let arrayController = NSArrayController()
        private var lastScrollPosition: CGPoint?
        
        public init(tableView: NSTableView, next: StringProcessor.Proto? = nil) {
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
