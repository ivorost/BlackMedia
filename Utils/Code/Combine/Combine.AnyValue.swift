//
//  Combine.AnyValue.swift
//  Utils-macOS
//
//  Created by Ivan Kh on 05.01.2023.
//

import Combine

public protocol ValuePublisher: Publisher {
    var value: Output { get }
}


extension CurrentValueSubject: ValuePublisher {}


public struct AnyValuePublisher<Output, Failure>: ValuePublisher where Failure: Error {

    nonisolated public var value: Output {
        box.value
    }

    private let box: PublisherBoxBase<Output, Failure>

    public init<T: ValuePublisher>(_ valuePublisher: T) where T.Output == Output, T.Failure == Failure {

        if let erased = valuePublisher as? AnyValuePublisher<Output, Failure> {
            self.box = erased.box
        } else {
            self.box = PublisherBox(base: valuePublisher)
        }
    }

    nonisolated public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        box.receive(subscriber: subscriber)
    }
}


extension AnyValuePublisher {
    private class PublisherBoxBase<Output, Failure: Error>: ValuePublisher {
        internal var value: Output {
            fatalError("abstract method")
        }

        internal init() {}

        internal func receive<Downstream: Subscriber>(subscriber: Downstream)
            where Failure == Downstream.Failure, Output == Downstream.Input {
            fatalError("abstract method")
        }
    }

    private final class PublisherBox<PublisherType: ValuePublisher>: PublisherBoxBase<PublisherType.Output, PublisherType.Failure> {
        internal let base: PublisherType

        internal override var value: PublisherType.Output {
            base.value
        }

        internal init(base: PublisherType) {
            self.base = base
        }

        internal override func receive<Downstream: Subscriber>(subscriber: Downstream) where Failure == Downstream.Failure, Output == Downstream.Input {
            base.receive(subscriber: subscriber)
        }
    }
}


extension Publisher where Self: ValuePublisher {
    public func eraseToAnyValuePublisher() -> AnyValuePublisher<Output, Failure> {
        AnyValuePublisher(self)
    }
}
