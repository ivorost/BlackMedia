//
//  Swift.Collection.swift
//  Capture
//
//  Created by Ivan Kh on 11.12.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import Foundation

public extension Array {
    @inlinable mutating func removeFirst(where shouldBeRemoved: (Element) -> Bool) -> Element? {
        for i in 0 ..< count {
            if shouldBeRemoved(self[i]) {
                return self.remove(at: i)
            }
        }
        
        return nil
    }
}
