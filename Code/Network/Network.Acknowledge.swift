//  Created by Ivan Kh on 03.05.2023.

import Foundation

public extension Network {
    struct Acknowledge {}
}

public extension Network.Acknowledge {
    class Answer : Network.PacketDeserializer.Processor {
        private var network: Data.Processor.AnyProto?

        init(network: Data.Processor.AnyProto?) {
            self.network = network
        }

        override func process(packet input: inout Network.PacketDeserializer) throws {
            let output = Network.PacketSerializer(type: .ack, id: input.id)
            network?.process(output.data)
        }
    }
}

public extension Network.Acknowledge {
    class Handler : Network.PacketDeserializer.Processor {
        private var hot: StageHotBase
        private var cold: StageColdBase

        init(hot: StageHotBase, cold: StageColdBase) {
            self.hot = hot
            self.cold = cold
            super.init(type: .ack)
        }

        override func process(packet input: inout Network.PacketDeserializer) throws {
            hot.flush(id: input.id)
            cold.flush()
        }
    }
}

public extension Network.Acknowledge {
    class StageHotBase {
        var isEmpty: Bool { true }
        func flush(id: UInt64) {}
    }

    class StageHot<T>: StageHotBase, ProcessorProtocol, ProducerProtocol {
        public var next: (any ProcessorProtocol<T>)?

        private var awaitingID: UInt64?
        private var buffer: T?
        private let lock = NSLock()

        override var isEmpty: Bool {
            buffer == nil
        }

        func id(for value: T) -> UInt64? {
            nil
        }

        public func process(_ value: T) {
            lock.withLock {
                if awaitingID == nil {
                    awaitingID = id(for: value)
                    next?.process(value)
                }
                else {
                    buffer = value
                }
            }
        }

        override func flush(id: UInt64) {
            lock.withLock {
                guard id == awaitingID else { return }

                if let buffer {
                    next?.process(buffer)
                }

                awaitingID = nil
                buffer = nil
            }
        }
    }
}

public extension Network.Acknowledge {
    class StageColdBase {
        func flush() {}
    }

    class StageCold<T>: StageColdBase, ProcessorProtocol, ProducerProtocol {
        public var next: (any ProcessorProtocol<T>)?
        private var hot: StageHotBase
        private var buffer: T?
        private let lock = NSLock()

        init(_ hot: StageHotBase) {
            self.hot = hot
        }

        public func process(_ value: T) {
            lock.withLock {
                if hot.isEmpty {
                    next?.process(value)
                }
                else {
                    buffer = value
                }
            }
        }

        override func flush() {
            lock.withLock {
                guard let buffer else { return }
                next?.process(buffer)
                self.buffer = nil
            }
        }
    }
}
