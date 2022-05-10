//
//  Video.Threading.swift
//  Capture
//
//  Created by Ivan Kh on 18.11.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation


public extension Video.Setup {
    class Multithreading : Video.Setup.Slave {
        private let queue: OperationQueue
        private let kind: Video.Processor.Kind
        
        public init(root: Video.Setup.Proto, kind: Video.Processor.Kind, queue: OperationQueue) {
            self.queue = queue
            self.kind = kind
            super.init(root: root)
        }
        
        public override func video(_ video: Video.Processor.Proto, kind: Video.Processor.Kind) -> Video.Processor.Proto {
            var result = video
            
            if kind == kind {
                result = Video.Processor.Dispatch(next: result, queue: queue)
            }
            
            return super.video(result, kind: kind)
        }
    }
}
