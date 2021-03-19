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
    var region: Region!

    override func setUpWithError() throws {
        super.setUp()
        region = Region(template: RegionTemplate())
    }

    override func tearDownWithError() throws {
        region = nil
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testRelativeYPosition() {
        region.proximalBoundaryY = 200
        region.distalBoundaryY = 500
        XCTAssertNotNil(region.relativeYPosition(y: 300))
        XCTAssertNotNil(region.relativeYPosition(y: 200))
        XCTAssertNotNil(region.relativeYPosition(y: 500))
        XCTAssertEqual(region.relativeYPosition(y: 300)!, 0.3333, accuracy: 0.001)
        XCTAssertNil(region.relativeYPosition(y: 199))
    }
}
