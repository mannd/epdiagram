//
//  FileTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 6/28/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class FileTests: XCTestCase {

    func testCleanupFilename() {
        var filename = DiagramIO.cleanupFilename("x:x/y:z")
        XCTAssertEqual("x_x_y_z", filename)
        filename = DiagramIO.cleanupFilename("abcde.tmp")
        XCTAssertEqual("abcde.tmp", filename)
        filename = DiagramIO.cleanupFilename("abcde\ntmp")
        XCTAssertEqual("abcde_tmp", filename)
    }

}
