//
//  DiagramTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 7/19/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class DiagramTests: XCTestCase {

    func testIsSaved() {
        var diagram = Diagram(name: nil, image: UIImage(named: "SampleECG")!, description: "")
        XCTAssertEqual(nil, diagram.name)
        XCTAssertEqual(false, diagram.isSaved)
        diagram.name = "test"
        XCTAssertEqual(true, diagram.isSaved)
    }

}
