//
//  General.Processor.swift
//  Core
//
//  Created by Ivan Kh on 03.04.2023.
//

import Foundation

public protocol ProcessorProtocol<ProcessorValue>: AnyObject {
    associatedtype ProcessorValue
    func process(_ value: ProcessorValue)
}

public class ProcessorToolbox<TValue> {
    public typealias Proto = ProcessorProtocol
    public typealias TheProto = ProcessorProtocol<TValue>
    public typealias AnyProto = any ProcessorProtocol<TValue>
}

public extension ProcessorToolbox {
    class Base : ProcessorProtocol {
        public func process(_ string: TValue) {}
    }
}

fileprivate class Broadcast<TProcessor>: ProcessorProtocol where TProcessor: ProcessorProtocol {
    typealias Value = TProcessor.ProcessorValue
    private let array: [TProcessor?]

    init(_ array: [TProcessor?]) {
        self.array = array
    }

    public func process(_ value: Value) {
        for i in array { i?.process(value) }
    }
}

public extension ProcessorToolbox {
    static func broadcast<TProcessor>(_ x: [TProcessor]) -> AnyProto
    where TProcessor: ProcessorProtocol, TProcessor.ProcessorValue == TValue {
        return Broadcast(x)
    }
}

extension ProcessorToolbox {
    class Callback: Data.Processor.Proto {
        private let callback: (TValue) -> Void

        init(callback: @escaping (TValue) -> Void) {
            self.callback = callback
        }

        func process(_ value: TValue) {
            callback(value)
        }
    }

}
