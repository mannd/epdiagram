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
        XCTAssertTrue(Common.getX(onSegment: testSegment1, fromY: 0.25) == nil, "identical y values should give nil")
        let testSegment2 = Segment(proximal: CGPoint(x: 0, y: 0.10), distal: CGPoint(x: 50, y: 0.80))
        XCTAssertTrue(Common.getX(onSegment: testSegment2, fromY: 0.05) == nil, "identical y values should give nil")
        let testSegment3 = Segment(proximal: CGPoint(x: 50, y: 0.10), distal: CGPoint(x: 50, y: 0.80))
        XCTAssertTrue(Common.getX(onSegment: testSegment3, fromY: 0.60) == 50, "x should be constant and equal to 50")
        XCTAssertTrue(Common.getX(onSegment: testSegment3, fromY: 0.90) == nil, "x should be constant but this y is still out of range and should be nil")
        let testSegment4 = Segment(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: 1.0, y: 1.0))
        XCTAssertTrue(Common.getX(onSegment: testSegment4, fromY: 0.5) == 0.5, "slope is 1, points should be equal x and y")
        
        
    }

}
