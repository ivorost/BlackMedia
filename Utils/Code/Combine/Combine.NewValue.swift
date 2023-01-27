//
//  Combine.NewValue.swift
//  Utils
//
//  Created by Ivan Kh on 21.01.2023.
//

import Combine

public protocol NewValuePublisher: ValuePublisher {
    var newValue: Output { get }
}


public struct AnyNewValuePublisher<Output, Failure>: NewValuePublisher where Failure: Error {

    nonisolated public var value: Output {
        box.value
    }

    nonisolated public var newValue: Output {
        box.newValue
    }

    private let box: PublisherBoxBase<Output, Failure>

    public init<T: NewValuePublisher>(_ valuePublisher: T) where T.Output == Output, T.Failure == Failure {

        if let erased = valuePublisher as? AnyNewValuePublisher<Output, Failure> {
            self.box = erased.box
        } else {
            self.box = PublisherBox(base: valuePublisher)
        }
    }

    nonisolated public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        box.receive(subscriber: subscriber)
    }
}


extension AnyNewValuePublisher {
    private class PublisherBoxBase<Output, Failure: Error>: NewValuePublisher {
        internal var value: Output {
            fatalError("abstract method")
        }

        internal var newValue: Output {
            fatalError("abstract method")
        }

        internal init() {}

        internal func receive<Downstream: Subscriber>(subscriber: Downstream)
            where Failure == Downstream.Failure, Output == Downstream.Input {
            fatalError("abstract method")
        }
    }

    private final class PublisherBox<PublisherType: NewValuePublisher>: PublisherBoxBase<PublisherType.Output, PublisherType.Failure> {
        internal let base: PublisherType

        internal override var value: PublisherType.Output {
            base.value
        }

        internal override var newValue: PublisherType.Output {
            base.newValue
        }

        internal init(base: PublisherType) {
            self.base = base
        }

        internal override func receive<Downstream: Subscriber>(subscriber: Downstream) where Failure == Downstream.Failure, Output == Downstream.Input {
            base.receive(subscriber: subscriber)
        }
    }
}


public class NewValueSubject<Output, Failure> : Subject where Failure : Error {

    public private(set) var newValue: Output
    private var inner: CurrentValueSubject<Output, Failure>

    public init(_ value: Output) {
        newValue = value
        inner = .init(value)
    }

    public var value: Output {
        inner.value
    }

    public func send(_ value: Output) {
        newValue = value
        inner.send(value)
    }

    public func send(completion: Subscribers.Completion<Failure>) {
        inner.send(completion: completion)
    }

    public func send(subscription: Subscription) {
        inner.send(subscription: subscription)
    }

    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        inner.receive(subscriber: subscriber)
    }
}


extension NewValueSubject: NewValuePublisher {}

extension Publisher where Self: NewValuePublisher {
    public func eraseToAnyNewValuePublisher() -> AnyNewValuePublisher<Output, Failure> {
        AnyNewValuePublisher(self)
    }
}
