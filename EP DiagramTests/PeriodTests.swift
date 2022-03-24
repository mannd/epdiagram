//
//  PeriodTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 3/24/22.
//  Copyright © 2022 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class PeriodTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIsSimilar() {
        let period1 = Period()
        let period2 = Period()
        XCTAssert(period1 != period2)
        XCTAssert(period1.isSimilarTo(period: period2))
        XCTAssert(period2.isSimilarTo(period: period1))
        var period3 = Period()
        XCTAssert(period3.isSimilarTo(period: period1))
        period3.name = "new name"
        XCTAssertFalse(period3.isSimilarTo(period: period1))
        XCTAssertFalse(period1.isSimilarTo(period: period3))
    }

    func testPeriodsAreSimilar() {
        let periods1 = [Period(), Period(), Period()]
        let periods2 = [Period(), Period(), Period()]
        let periods3 = [Period(), Period()]
        let periods4: [Period] = []
        XCTAssert(Period.periodsAreSimilar(periods1, periods2))
        XCTAssertFalse(Period.periodsAreSimilar(periods2, periods3))
        XCTAssertFalse(Period.periodsAreSimilar(periods3, periods4))
        let periods5 = [Period(name: "test"), Period(), Period()]
        XCTAssertFalse(Period.periodsAreSimilar(periods2, periods5))
        let periods6 = [Period(duration: 0), Period()]
        XCTAssertFalse(Period.periodsAreSimilar(periods3, periods6))
        let periods7 = [Period(), Period(duration: 0)]
        XCTAssertFalse(Period.periodsAreSimilar(periods6, periods7))
        let periods8 = [Period(color: UIColor.blue), Period()]
        XCTAssertFalse(Period.periodsAreSimilar(periods3, periods8))
        let periods9 = [Period(color: UIColor.blue), Period()]
        XCTAssert(Period.periodsAreSimilar(periods8, periods9))
        let periods10 = periods9
        XCTAssert(Period.periodsAreSimilar(periods10, periods9))
        let periods11 = periods4 // empty arrays are considered to be similar
        XCTAssert(Period.periodsAreSimilar(periods11, periods4))
    }

}
