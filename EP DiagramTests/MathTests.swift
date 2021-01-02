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
        XCTAssertTrue(Common.distance(fromSegment: s1, toSegment: s2) == 50, "should be 50")
        let s3 = s1
        XCTAssertTrue(Common.distance(fromSegment: s1, toSegment: s3) == 0, "segments are equal")
        // segments intersect
        // Right now not testing for segment intersection, as intersecting segments are not considered to be nearby segments.  I.e. we don't want to group together intersecting segments.
//        let s4 = Segment(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: 1, y: 1))
//        let s5 = Segment(proximal: CGPoint(x: 1, y: 0), distal: CGPoint(x: 0, y: 1))
//        P("distance = \(Common.distance(fromSegment: s4, toSegment: s5))")
//        XCTAssertTrue(Common.distance(fromSegment: s4, toSegment: s5) == 0, "segments intersect")
    }

}
