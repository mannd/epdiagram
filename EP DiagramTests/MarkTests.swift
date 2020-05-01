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
        let mark = Mark(segment: Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 100, y: 1.0)))
        XCTAssertEqual(mark.segment.proximal.x, 100)
        XCTAssertEqual(mark.segment.distal.x, 100)
    }

    func testMarkHeight() {
        let mark = Mark(positionX: 0)
        XCTAssertEqual(mark.height, 1.0)
        let mark2 = Mark(segment: Segment(proximal: CGPoint(x: 1, y: 0.25), distal: CGPoint(x: 2, y: 0.75)))
        XCTAssertEqual(mark2.height, 0.5, accuracy: 0.001)
    }

    func testMarkLength() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x: 0.5, y: 0.8), distal: CGPoint(x: 0.9, y: 0.2)))
        XCTAssertEqual(mark.length, 0.721110255092798, accuracy: 0.001)
    }

    func testMarkDistanceToPoint() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x: 1, y: 0), distal: CGPoint(x: 1, y: 1)))
        let point = CGPoint(x: 1.5, y: 0.5)
        XCTAssertEqual(mark.distance(point: point), 0.5, accuracy: 0.001)
        let point2 = CGPoint(x: 1, y: 0.5)
        let mark2 = Mark(segment: Segment(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: 2, y: 1)))
        XCTAssertEqual(mark2.distance(point: point2), 0, accuracy: 0.001)
        let mark3 = Mark(segment: Segment(proximal: CGPoint(x: 1, y: 0.7), distal: CGPoint(x: 2, y: 0.9)))
        let point3 = CGPoint(x: 2, y: 0.7)
        XCTAssertEqual(mark3.distance(point: point3), 0.1961, accuracy: 0.001)
    }

    func testMidpoint() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x: 50, y: 0.21), distal: CGPoint(x:120, y: 0.88)))
        let region = Region(index: 0)
        region.proximalBoundary = 100
        region.distalBoundary = 500
        let relativeMarkPosition = Common.translateToScaledViewSegment(regionSegment: mark.segment, region: region, offsetX: 0, scale: 1)
        P("relativeMarkPosition = \(relativeMarkPosition)")
        let midPoint = Common.getSegmentMidpoint(relativeMarkPosition)
        XCTAssertEqual(midPoint, CGPoint(x: 85, y: 318))
        let anotherMarkPosition = Segment(proximal: CGPoint(x: -3, y: 5), distal: CGPoint(x: 8, y: -1))
        let anotherMidPoint = Common.getSegmentMidpoint(anotherMarkPosition)
        XCTAssertEqual(anotherMidPoint, CGPoint(x: 2.5, y: 2))
    }

    func testNormalization() {
        let p1 = CGPoint(x: 1, y: 1.5)
        XCTAssertEqual(p1.normalized().y, 1.0, accuracy: 0.00001)
        let p2 = CGPoint(x: 2, y: -1.5)
        XCTAssertEqual(p2.normalized().y, 0, accuracy: 0.00001)
        let s1 = Segment(proximal: p1, distal: p2)
        let normalizedS1 = s1.normalized()
        XCTAssertEqual(normalizedS1.proximal.y, 1.0, accuracy: 0.00001)
        XCTAssertEqual(normalizedS1.distal.y, 0, accuracy: 0.00001)
        let p3 = CGPoint(x: 100, y: 0.7)
        XCTAssertEqual(p3.y, 0.7, accuracy: 0.00001)
        XCTAssertEqual(p3.x, 100, accuracy: 0.00001)
    }

    func testMarkSet() {
        let mark1 = Mark()
        let mark2 = Mark()
        let mark3 = Mark()
        var markGroup = MarkGroup()
        markGroup.proximal.insert(mark1)
        markGroup.middle.insert(mark2)
        markGroup.distal.insert(mark3)
        let allMarks = markGroup.allMarks
        XCTAssert(allMarks.count == 3, "should be 3 elements in allMarks")
        XCTAssert(allMarks.contains(mark1))
        XCTAssert(allMarks.contains(mark2))
        XCTAssert(allMarks.contains(mark3))
    }

}
