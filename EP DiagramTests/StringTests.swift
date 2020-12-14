//
//  StringTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 7/19/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class StringTests: XCTestCase {
    var string: String = "string"
    var optionalString: String? = "optionalString"

    func testIsBlank() {
        XCTAssertEqual(false, string.isBlank)
        XCTAssertEqual(false, optionalString.isBlank)
        string = "   "
        optionalString = "   "
        XCTAssertEqual(true, string.isBlank)
        XCTAssertEqual(true, optionalString.isBlank)
        string = ""
        optionalString = ""
        XCTAssertEqual(true, string.isBlank)
        XCTAssertEqual(true, optionalString.isBlank)
        optionalString = nil
        XCTAssertEqual(true, optionalString.isBlank)
        optionalString = "test"
        XCTAssertEqual(false, optionalString.isBlank)
        string = "test"
        XCTAssertEqual(false, string.isBlank)
    }
}
