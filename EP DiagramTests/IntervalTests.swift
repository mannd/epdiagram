//
//  IntervalTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 3/17/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram


class IntervalTests: XCTestCase {
    var ladder: Ladder!

    override func setUpWithError() throws {
        super.setUp()
        ladder = Ladder.defaultLadder()
    }

    override func tearDownWithError() throws {
        ladder = nil
        super.tearDown()
    }

    func testIntervalLimits() {
        let tolerance = Interval.boundaryTolerance
        let _ = ladder.addMark(at: 0, toRegion: ladder.regions[0])
        let mark2 = ladder.addMark(at: 100, toRegion: ladder.regions[0])
        var intervals = ladder.regionIntervals(region: ladder.regions[0])
        XCTAssertEqual(intervals.count, 2)
        XCTAssertEqual(intervals[0].proximalBoundary?.first!, 0)
        XCTAssertEqual(intervals[0].proximalBoundary?.second!, 100)
        XCTAssertEqual(intervals[1].distalBoundary?.first!, 0)
        XCTAssertEqual(intervals[1].distalBoundary?.second!, 100)
        mark2.segment = Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 200, y: 1.0))
        intervals = ladder.regionIntervals(region: ladder.regions[0])
        XCTAssertEqual(intervals[0].proximalBoundary?.first!, 0)
        XCTAssertEqual(intervals[0].proximalBoundary?.second!, 100)
        XCTAssertEqual(intervals[1].distalBoundary?.first!, 0)
        XCTAssertEqual(intervals[1].distalBoundary?.second!, 200)
        mark2.segment = Segment(proximal: CGPoint(x: 100, y: 0 + tolerance), distal: CGPoint(x: 200, y: 1.0 - tolerance))
        intervals = ladder.regionIntervals(region: ladder.regions[0])
        XCTAssertEqual(intervals[0].proximalBoundary?.first!, 0)
        XCTAssertEqual(intervals[0].proximalBoundary?.second!, 100)
        XCTAssertEqual(intervals[1].distalBoundary?.first!, 0)
        XCTAssertEqual(intervals[1].distalBoundary?.second!, 200)
        mark2.segment = Segment(proximal: CGPoint(x: 100, y: 0 + tolerance + 0.01), distal: CGPoint(x: 200, y: 1.0 - tolerance - 0.01))
        intervals = ladder.regionIntervals(region: ladder.regions[0])
        // Intervals should be empty because the ends of the 2nd mark are too far from the region boundary
        XCTAssertEqual(intervals.count, 0)
    }

}
