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
    private var ladderView: LadderView!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        cursorView = CursorView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        ladderView = LadderView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 100, height: 100)))
        cursorView.ladderViewDelegate = ladderView
        ladderView.cursorViewDelegate = cursorView
    }

    override func tearDown() {
        cursorView = nil
        ladderView = nil
    }

    func testIsNearCursor() {
        cursorView.moveCursor(cursorViewPositionX: 100)
        let nearCursor = cursorView.isNearCursor(positionX: 100, accuracy: 0.001)
        XCTAssert(nearCursor)
    }

    func testNewCalibration() {
        let calibration = cursorView.newCalibration(zoom: 1.7)
        XCTAssertTrue(calibration.isCalibrated)
    }

    func testAddMarkWithAttachedCursor() {
        cursorView.addMarkWithAttachedCursor(positionX: 100)
        XCTAssertEqual(cursorView.cursorIsVisible, true)
        XCTAssertEqual(cursorView.cursorPositionX, 100, accuracy: 0.0001)
    }
}
