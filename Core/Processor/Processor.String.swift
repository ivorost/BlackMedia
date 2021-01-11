//
//  Core.String.Processor.swift
//  Capture
//
//  Created by Ivan Kh on 18.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import AppKit

protocol StringProcessorProtocol {
    func process(string: String)
}


class StringProcessorChain : StringProcessorProtocol {
    let next: StringProcessorProtocol?
    
    init(next: StringProcessorProtocol?) {
        self.next = next
    }
    
    func process(string: String) {
        next?.process(string: string)
    }
}


class StringProcessorWithIntervalBase : StringProcessorProtocol, SessionProtocol {
    private let next: StringProcessorProtocol
    private let interval: TimeInterval
    private var timer: Timer?
    
    init(interval: TimeInterval, next: StringProcessorProtocol) {
        self.interval = interval
        self.next = next
    }

    convenience init(next: StringProcessorProtocol) {
        self.init(interval: 0.33, next: next)
    }
    
    func start() throws {
        timer = Timer.scheduledTimer(withTimeInterval: interval,
                                     repeats: true,
                                     block: { _ in self.flush() })
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    func process(string: String) {
        next.process(string: string)
    }
    
    func flush() {
    }
}


class StringProcessorWithIntervalCutting : StringProcessorWithIntervalBase {
    var string: String?
    
    override func process(string: String) {
        self.string = string
    }
    
    override func flush() {
        if let string = string {
            super.process(string: string)
        }
    }
}


class StringProcessorWithIntervalBatching : StringProcessorWithIntervalBase {
    var strings = [String]()
    let lock = NSLock()
    
    override func process(string: String) {
        lock.locked { strings.append(string) }
    }
    
    override func flush() {
        super.process(string: strings.joined(separator: "\n"))
        lock.locked { strings.removeAll() }
    }
}


class StringProcessorTableView : StringProcessorChain {
    private let tableView: NSTableView
    private let arrayController = NSArrayController()

    init(tableView: NSTableView, next: StringProcessorProtocol? = nil) {
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
