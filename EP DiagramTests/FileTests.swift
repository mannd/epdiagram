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
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let sut = sb.instantiateViewController(withIdentifier: String(describing: ViewController.self)) as! ViewController
        sut.loadViewIfNeeded()
        var filename = sut.cleanupFilename("x:x/y:z")
        XCTAssertEqual("x_x_y_z", filename)
        filename = sut.cleanupFilename("abcde.tmp")
        XCTAssertEqual("abcde.tmp", filename)
        filename = sut.cleanupFilename("abcde\ntmp")
        XCTAssertEqual("abcde_tmp", filename)
    }

}
