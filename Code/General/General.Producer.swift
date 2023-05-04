//
//  General.Producer.swift
//  Core
//
//  Created by Ivan Kh on 31.03.2023.
//

import Foundation

public protocol ProducerProtocol<ProducerValue>: AnyObject {
    associatedtype ProducerValue
    var next: (any ProcessorProtocol<ProducerValue>)? { get set }
}

public struct ProducerChain<TNext, TFirst> {
    var producer: any ProducerProtocol<TNext>
    public let first: any ProcessorProtocol<TFirst>
}

public class ProducerToolbox<TValue> {
    public typealias Proto = ProducerProtocol
    public typealias TheProto = ProducerProtocol<TValue>
    public typealias AnyProto = any ProducerProtocol<TValue>
}

public extension ProducerChain {
    @discardableResult func next<T>(_ next: T) -> ProducerChain<TNext, TFirst>
    where T: ProcessorProtocol<TNext> {

        let forward = ForwardProducer<T.ProcessorValue>(inner: next)
        self.producer.next = forward
        return ProducerChain(producer: forward, first: first)
    }

    @discardableResult func next<T>(_ next: T) -> ProducerChain<T.ProducerValue, TFirst>
    where T: ProducerProtocol & ProcessorProtocol<TNext> {
        self.producer.next = next
        return ProducerChain<T.ProducerValue, TFirst>(producer: next, first: first)
    }
}

public extension ProducerProtocol {
    @discardableResult func next<T>(_ next: T) -> ProducerChain<ProducerValue, ProducerValue>
    where T: ProcessorProtocol<ProducerValue> {
        let producer = ForwardProducer(inner: next)
        self.next = producer
        return ProducerChain(producer: producer, first: next)
    }

    @discardableResult func next<T>(_ next: T) -> ProducerChain<T.ProducerValue, ProducerValue>
    where T: ProducerProtocol & ProcessorProtocol<ProducerValue> {
        self.next = next
        return ProducerChain(producer: next, first: next)
    }
}

public extension ProcessorProtocol {
    func asProducer() -> ProducerChain<ProcessorValue, ProcessorValue> {
        let forward = ForwardProducer<ProcessorValue>(inner: self)
        return ProducerChain(producer: forward, first: forward)
    }
}

public class ForwardProducer<TValue>: ProducerProtocol, ProcessorProtocol {
    public typealias Next = any ProcessorProtocol<TValue>
    public typealias Value = TValue

    public var next: Next?
    let inner: Next

    init(inner: Next, next: Next? = nil) {
        self.inner = inner
        self.next = next
    }

    public func process(_ value: TValue) {
        inner.process(value)
        next?.process(value)
    }
}
