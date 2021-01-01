//
//  CursorViewTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 8/11/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class CursorViewTests: XCTestCase {
    private var cursorView: CursorView!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        cursorView = CursorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    override func tearDown() {
        cursorView = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIsNearCursor() {
        cursorView.moveCursor(cursorViewPositionX: 100)
        let nearCursor = cursorView.isNearCursor(positionX: 100, accuracy: 0.001)
        XCTAssert(nearCursor)
    }
}
