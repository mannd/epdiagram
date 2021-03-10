//
//  CalibrationTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 3/10/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram


class CalibrationTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetCalibration() {
        let value: CGFloat = 100
        let calibration = Calibration()
        calibration.set(zoom: 1.5, calFactor: Calibration.standardInterval / value)
        let calibration2 = Calibration()
        calibration2.set(zoom: 1.5, value: value)
        XCTAssertEqual(calibration.currentCalFactor, calibration2.currentCalFactor)
        XCTAssertTrue(calibration.isCalibrated)
        XCTAssertTrue(calibration2.isCalibrated)
        calibration.currentZoom = 1.0
        calibration2.currentZoom = 1.0
        XCTAssertEqual(calibration.currentCalFactor, calibration2.currentCalFactor)
    }



}
