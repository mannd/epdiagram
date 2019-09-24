//
//  ViewControllerTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 9/16/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class ViewControllerTests: XCTestCase {

    func test_loadViewController() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let sut = sb.instantiateViewController(withIdentifier: String(describing: ViewController.self)) as! ViewController
        sut.loadViewIfNeeded()
        // test view controller here
        // Testing my testing, these all must be non-nil if outlets are connected.
        XCTAssert(sut.ladderView != nil)
        XCTAssert(sut.imageView != nil)
        XCTAssert(sut.imageScrollView != nil)
        XCTAssert(sut.cursorView != nil)
    }
}
