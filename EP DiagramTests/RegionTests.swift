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
        let region = Region(index: 0)
        region.proximalBoundary = 200
        region.distalBoundary = 500
        XCTAssertNotNil(region.getRelativeYPosition(y: 300))
        XCTAssertEqual(region.getRelativeYPosition(y: 300)!, 0.3333, accuracy: 0.001)
    }

}
