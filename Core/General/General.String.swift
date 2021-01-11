//
//  Core.String.Processor.swift
//  Capture
//
//  Created by Ivan Kh on 18.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AppKit

protocol StringProcessorProto {
    func process(string: String)
}


class StringProcessorBase : StringProcessorProto {
    func process(string: String) {}
}


class StringProcessor : StringProcessorBase {
    static let shared = StringProcessor()
}


extension StringProcessor {
    typealias Base = StringProcessorBase
    typealias Proto = StringProcessorProto
}


extension StringProcessor {
    class Chain : Proto {
        let next: Proto?
        
        init(next: Proto?) {
            self.next = next
        }
        
        func process(string: String) {
            next?.process(string: string)
        }
    }
}


extension StringProcessor {
    class FlushLast : Chain, Flushable.Proto {
        private var string: String?
        
        init(_ next: StringProcessor.Proto?) {
            super.init(next: next)
        }
        
        override func process(string: String) {
            self.string = string
        }
        
        func flush() {
            if let string = string {
                super.process(string: string)
            }
        }
    }
}


extension StringProcessor {
    class FlushAll : Chain, Flushable.Proto {
        var strings = [String]()
        let lock = NSLock()
        
        init(_ next: StringProcessor.Proto?) {
            super.init(next: next)
        }

        override func process(string: String) {
            lock.locked { strings.append(string) }
        }
        
        func flush() {
            var joined = ""
            
            lock.locked {
                joined = strings.joined(separator: "\n")
                strings.removeAll()
            }
            
            super.process(string: joined)
        }
    }
}


extension StringProcessor {
    class TableView : Chain {
        private let tableView: NSTableView
        private let arrayController = NSArrayController()
        private var lastScrollPosition: CGPoint?
        
        init(tableView: NSTableView, next: StringProcessor.Proto? = nil) {
            self.tableView = tableView
            super.init(next: next)
            
            tableView.bind(.content,
                           to: arrayController,
                           withKeyPath: "arrangedObjects",
                           options: nil)
        }
        
        override func process(string: String) {
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
