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
        let diagram = Diagram(name: nil, description: "", image: UIImage(named: "SampleECG")!, ladder: Ladder.defaultLadder())
        XCTAssertEqual(nil, diagram.name)
    }

}
