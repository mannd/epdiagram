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
    var calibration: Calibration!

    override func setUpWithError() throws {
        super.setUp()
        calibration = Calibration()
    }

    override func tearDownWithError() throws {
        calibration = nil
        super.tearDown()
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
