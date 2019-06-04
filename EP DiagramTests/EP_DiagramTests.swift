//
//  EP_DiagramTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 4/29/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class EP_DiagramTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testPointIsNearCursor() {
        let cursor = Cursor(position: 100)
        XCTAssertTrue(cursor.isNearCursor(point: CGPoint(x: 105, y: 55)))
        XCTAssertFalse(cursor.isNearCursor(point: CGPoint(x: 115, y: 55)))
    }

}
