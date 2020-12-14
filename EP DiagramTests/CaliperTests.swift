//
//  CaliperTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 7/2/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

@testable import EP_Diagram
import XCTest

class CaliperTests: XCTestCase {
    private var caliper: Caliper!

    override func setUp() {
        super.setUp()
        caliper = Caliper()
        caliper.maxY = 100
    }

    override func tearDown() {
        caliper = nil
        super.tearDown()
    }

    func testCaliperProximity() {
        caliper.bar1Position = 50
        caliper.bar2Position = 100
        caliper.crossbarPosition = 50
        let accuracy: CGFloat = 10
        XCTAssertEqual(Caliper.Component.bar1, caliper.isNearCaliperComponent(point: CGPoint(x: 50, y: 50), accuracy: accuracy))
        XCTAssertEqual(Caliper.Component.bar2, caliper.isNearCaliperComponent(point: CGPoint(x: 100, y: 50), accuracy: accuracy))
        XCTAssertEqual(Caliper.Component.crossbar, caliper.isNearCaliperComponent(point: CGPoint(x: 0, y: 50), accuracy: accuracy))
        XCTAssertEqual(true, caliper.isNearCaliper(point: CGPoint(x: 0, y: 50), accuracy: accuracy))
        XCTAssertEqual(nil, caliper.isNearCaliperComponent(point: CGPoint(x: 80, y: 80), accuracy: accuracy))
        XCTAssertEqual(false, caliper.isNearCaliper(point: CGPoint(x: 80, y: 80), accuracy: accuracy))
    }

    func testCaliperMovement() {
        caliper.bar1Position = 10
        caliper.bar2Position = 50
        caliper.crossbarPosition = 50
        let delta = CGPoint(x: 5, y: 10)
        caliper.move(delta: delta, component: .bar1)
        XCTAssertEqual(15, caliper.bar1Position)
        caliper.move(delta: delta, component: .bar2)
        XCTAssertEqual(55, caliper.bar2Position)
        caliper.move(delta: delta, component: .crossbar)
        XCTAssertEqual(60, caliper.crossbarPosition)
        XCTAssertEqual(20, caliper.bar1Position)
        XCTAssertEqual(60, caliper.bar2Position)
    }

    func testCaliperValue() {
        caliper.bar1Position = 90
        caliper.bar2Position = 120
        XCTAssertEqual(30, caliper.value, accuracy: 0.00001)
        caliper.bar1Position = -10
        caliper.bar2Position = 30
        XCTAssertEqual(40, caliper.value, accuracy: 0.00001)
        caliper.bar1Position = 0
        caliper.bar2Position = 0
        XCTAssertEqual(0, caliper.value, accuracy: 0.00001)
    }
}
