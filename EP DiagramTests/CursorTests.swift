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
    var cursor: Cursor!

    override func setUp() {
        super.setUp()
        cursor = Cursor(positionX: 100)
    }

    override func tearDown() {
        cursor = nil
        super.tearDown()
    }

    func testPointIsNearCursor() {
        // Assumes differential of 40.
        XCTAssertTrue(cursor.isNearCursor(point: CGPoint(x: 105, y: 55), accuracy: 20))
        XCTAssertFalse(cursor.isNearCursor(point: CGPoint(x: 145, y: 55), accuracy: 20))
    }

    func testCursorMove() {
        cursor.move(delta: CGPoint(x: 20, y: 20))
        XCTAssertEqual(cursor.positionX, 120)
    }
}
