//
//  Swift.Concurrency.TaskQueue.swift
//  Utils
//
//  Created by Ivan Kh on 16.12.2022.
//

import Foundation


public class TaskQueue {
    private actor Actor {
        private let maxConcurrentTasksCount: Int
        private var running: Int = 0
        private var queue = [CheckedContinuation<Void, Error>]()

        public init(maxConcurrentTasksCount: Int = 1) /* serial by default */ {
            self.maxConcurrentTasksCount = maxConcurrentTasksCount
        }

        deinit {
            for continuation in queue {
                continuation.resume(throwing: CancellationError())
            }
        }

        public func enqueue<T>(operation: @escaping @Sendable () async throws -> T) async throws -> T {
            try Task.checkCancellation()

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                queue.append(continuation)
                tryRunEnqueued()
            }

            defer {
                running -= 1
                tryRunEnqueued()
            }
            
            try Task.checkCancellation()
            return try await operation()
        }

        private func tryRunEnqueued() {
            guard !queue.isEmpty else { return }
            guard running < maxConcurrentTasksCount else { return }

            running += 1
            let continuation = queue.removeFirst()
            continuation.resume()
        }
    }
    
    private let actor = Actor()
    
    public init() {
    }

    public func task(operation: @escaping @Sendable () async -> Void) {
        Task {
            try! await actor.enqueue {
                await operation()
            }
        }
    }

    public func task<T>(operation: @escaping @Sendable () async -> T) async -> T {
        try! await actor.enqueue {
            await operation()
        }
    }

    public func task<T>(operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await actor.enqueue(operation: operation)
    }
}
