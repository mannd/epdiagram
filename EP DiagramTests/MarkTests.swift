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

}
