//
//  MathTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 4/30/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class MathTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testGetXOnSegment() {
        let testSegment1 = Segment(proximal: CGPoint(x: 0, y: 0.25), distal: CGPoint(x: 50, y: 0.25))
        XCTAssertTrue(testSegment1.getX(fromY: 0.25) == nil, "identical y values should give nil")
        let testSegment2 = Segment(proximal: CGPoint(x: 0, y: 0.10), distal: CGPoint(x: 50, y: 0.80))
        XCTAssertTrue(testSegment2.getX(fromY: 0.05) == nil, "identical y values should give nil")
        let testSegment3 = Segment(proximal: CGPoint(x: 50, y: 0.10), distal: CGPoint(x: 50, y: 0.80))
        XCTAssertTrue(testSegment3.getX(fromY: 0.60) == 50, "x should be constant and equal to 50")
        XCTAssertTrue(testSegment3.getX(fromY: 0.90) == nil, "x should be constant but this y is still out of range and should be nil")
        let testSegment4 = Segment(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: 1.0, y: 1.0))
        XCTAssertTrue(testSegment4.getX(fromY: 0.5) == 0.5, "slope is 1, points should be equal x and y")
    }

    func testSegmentDistances() {
        // parallel lines
        let s1 = Segment(proximal: CGPoint(x: 0, y: 100), distal: CGPoint(x: 0, y: 50))
        let s2 = Segment(proximal: CGPoint(x: 50, y: 100), distal: CGPoint(x: 50, y: 50))
        XCTAssertTrue(Geometry.distance(fromSegment: s1, toSegment: s2) == 50, "should be 50")
        let s3 = s1
        XCTAssertTrue(Geometry.distance(fromSegment: s1, toSegment: s3) == 0, "segments are equal")
        // segments intersect
        // Right now not testing for segment intersection, as intersecting segments are not considered to be nearby segments.  I.e. we don't want to group together intersecting segments.
//        let s4 = Segment(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: 1, y: 1))
//        let s5 = Segment(proximal: CGPoint(x: 1, y: 0), distal: CGPoint(x: 0, y: 1))
//        P("distance = \(Common.distance(fromSegment: s4, toSegment: s5))")
//        XCTAssertTrue(Common.distance(fromSegment: s4, toSegment: s5) == 0, "segments intersect")
    }

    func testParallelSegments() {
        let s1 = Segment(proximal: CGPoint(x: 100, y: 100), distal: CGPoint(x: 100, y: 100))
        XCTAssertTrue(Geometry.areParallel(s1, s1))
        let s2 = Segment(proximal: CGPoint(x: 200, y: 100), distal: CGPoint(x: 200, y: 50))
        XCTAssertTrue(Geometry.areParallel(s1, s2))
        let s3 = Segment(proximal: CGPoint(x: 200, y: 100), distal: CGPoint(x: 201, y: 50))
        XCTAssertFalse(Geometry.areParallel(s1, s3))
        let s4 = Segment(proximal: CGPoint(x: 100, y: 50), distal: CGPoint(x: 150, y: 100))
        let s5 = Segment(proximal: CGPoint(x: 110, y: 50), distal: CGPoint(x: 160, y: 100))
        XCTAssertTrue(Geometry.areParallel(s4, s5))
        let s6 = Segment(proximal: CGPoint(x: 110, y: 50), distal: CGPoint(x: 160.1, y: 100))
        XCTAssertFalse(Geometry.areParallel(s4, s6))
    }

    func testOppositeAngle() {
        let s1 = Segment(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: 1, y: 1))
        let angle1 = Geometry.oppositeAngle(p1: s1.proximal, p2: s1.distal)
        XCTAssertEqual(angle1, 45, accuracy: 0.0001)
        let angle2 = Geometry.oppositeAngle(p1: s1.distal, p2: s1.proximal)
        XCTAssertEqual(angle2, -45, accuracy: 0.0001)
        let s3 = Segment(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: -1, y: -1))
        let angle3 = Geometry.oppositeAngle(p1: s3.proximal, p2: s3.distal)
        XCTAssertEqual(angle3, -45, accuracy: 0.0001)
    }

    func testEvaluateX() {
        let s0 = Segment(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: 0, y: 100))
        XCTAssertEqual(Geometry.evaluateX(knowingY: 50, fromSegment: s0), 0, accuracy: 0.001)
        let s1 = Segment(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: 100, y: 100))
        XCTAssertEqual(Geometry.evaluateX(knowingY: 50, fromSegment: s1), 50, accuracy: 0.001)
        let s2 = Segment(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: -100, y: -100))
        XCTAssertEqual(Geometry.evaluateX(knowingY: -50, fromSegment: s2), -50, accuracy: 0.001)
    }

}
