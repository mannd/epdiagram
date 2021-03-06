//
//  RegionTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 5/7/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class RegionTests: XCTestCase {

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

    func testRelativeYPosition() {
        let region = Region(template: RegionTemplate())
        region.proximalBoundaryY = 200
        region.distalBoundaryY = 500
        XCTAssertNotNil(region.relativeYPosition(y: 300))
        XCTAssertNotNil(region.relativeYPosition(y: 200))
        XCTAssertNotNil(region.relativeYPosition(y: 500))
        XCTAssertEqual(region.relativeYPosition(y: 300)!, 0.3333, accuracy: 0.001)
        XCTAssertNil(region.relativeYPosition(y: 199))
    }

}
