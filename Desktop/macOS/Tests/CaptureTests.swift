//
//  CaptureTests.swift
//  CaptureTests
//
//  Created by Ivan Kh on 26.10.2020.
//  Copyright © 2020 Ivan Kh. All rights reserved.
//

import XCTest
@testable import Desktop

class CaptureTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMeasureCPS() throws {
        var result: Double?
        let measure = MeasureCPS { result = $0 }
        
        measure.measure(count: 1)
        Thread.sleep(forTimeInterval: 0.1)
        measure.measure(count: 1)
        Thread.sleep(forTimeInterval: 0.1)
        measure.measure(count: 1)
        Thread.sleep(forTimeInterval: 0.1)
        measure.measure(count: 1)

        XCTAssert(fabs(result! - 10.0) < 0.25)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
