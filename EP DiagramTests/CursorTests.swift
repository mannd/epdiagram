//
//  CursorTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 7/21/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class CursorTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPointIsNearCursor() {
        let cursor = Cursor(positionX: 100)
        // Assumes differential of 40.
        XCTAssertTrue(cursor.isNearCursor(point: CGPoint(x: 105, y: 55), accuracy: 20))
        XCTAssertFalse(cursor.isNearCursor(point: CGPoint(x: 145, y: 55), accuracy: 20))
    }

    func testCursorMove() {
        let cursor = Cursor(positionX: 100)
        cursor.move(delta: CGPoint(x: 20, y: 20))
        XCTAssertEqual(cursor.positionX, 120)
    }
}
