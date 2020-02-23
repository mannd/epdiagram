//
//  MarkTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 7/26/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class MarkTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMarkLocation() {
        let mark = Mark(MarkPosition(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 100, y: 1.0)))
        XCTAssertEqual(mark.position.proximal.x, 100)
        XCTAssertEqual(mark.position.distal.x, 100)
    }

    func testMarkHeight() {
        let mark = Mark(positionX: 0)
        XCTAssertEqual(mark.height, 1.0)
        let mark2 = Mark(MarkPosition(proximal: CGPoint(x: 1, y: 0.25), distal: CGPoint(x: 2, y: 0.75)))
        XCTAssertEqual(mark2.height, 0.5, accuracy: 0.001)
    }

    func testMarkLength() {
        let mark = Mark(MarkPosition(proximal: CGPoint(x: 0.5, y: 0.8), distal: CGPoint(x: 0.9, y: 0.2)))
        XCTAssertEqual(mark.length, 0.721110255092798, accuracy: 0.001)
    }

    func testMarkDistanceToPoint() {
        let mark = Mark(MarkPosition(proximal: CGPoint(x: 1, y: 0), distal: CGPoint(x: 1, y: 1)))
        let point = CGPoint(x: 1.5, y: 0.5)
        XCTAssertEqual(mark.distance(point: point), 0.5, accuracy: 0.001)
        let point2 = CGPoint(x: 1, y: 0.5)
        let mark2 = Mark(MarkPosition(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: 2, y: 1)))
        XCTAssertEqual(mark2.distance(point: point2), 0, accuracy: 0.001)
        let mark3 = Mark(MarkPosition(proximal: CGPoint(x: 1, y: 0.7), distal: CGPoint(x: 2, y: 0.9)))
        let point3 = CGPoint(x: 2, y: 0.7)
        XCTAssertEqual(mark3.distance(point: point3), 0.1961, accuracy: 0.001)
    }

}
