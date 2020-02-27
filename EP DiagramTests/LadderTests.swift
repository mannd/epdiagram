//
//  LadderTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 7/21/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class LadderTests: XCTestCase {
    private var ladder: Ladder!

    override func setUp() {
        super.setUp()
        ladder = Ladder.defaultLadder()
    }

    override func tearDown() {
        ladder = nil
        super.tearDown()
    }

    func testDefaultRegionLabels() {
        var region = ladder.regions[0] // A region
        XCTAssertEqual(region.name, "A")
        region = ladder.regions[1] // AV region
        XCTAssertEqual(region.name, "AV")
        region = ladder.regions[2] // V region
        XCTAssertEqual(region.name, "V")
    }

    func testNumberOfRegionsInDefaultLadder() {
        XCTAssertEqual(ladder.numRegions, 3)
    }

    func testDefaultRegionMarks() {
        for region in ladder.regions {
            // default ladder has no marks
            XCTAssertEqual(region.marks.count, 0)
        }
    }

    func testAddMark() {
        ladder.activeRegion = ladder.regions[0]
        let mark = ladder.addMarkAt(100)
        XCTAssertEqual(mark?.segment.proximal.x, 100)
    }

    func testAddMarkNoActiveRegion() {
        ladder.activeRegion = nil
        let mark = ladder.addMarkAt(100)
        XCTAssertEqual(mark?.segment.proximal.x, nil)
    }

    func testGetRegionIndex() {
        ladder.activeRegion = ladder.regions[1]
        XCTAssertEqual(ladder.getRegionIndex(region: ladder.activeRegion), 1)
        XCTAssert(ladder.getRegionAfter(region: ladder.activeRegion) === ladder.regions[2])
        XCTAssert(ladder.getRegionBefore(region: ladder.activeRegion) === ladder.regions[0])
        let regionBefore = ladder.getRegionBefore(region: ladder.activeRegion)
        XCTAssertNil(ladder.getRegionBefore(region: regionBefore))
        let regionAfter = ladder.getRegionAfter(region: ladder.activeRegion)
        XCTAssertNil(ladder.getRegionAfter(region: regionAfter))
    }

    func testRegionsEqual() {
        let region1 = ladder.regions[0]
        let region2 = ladder.regions[1]
        XCTAssert(!(region1 === region2))
        let region3 = region1
        XCTAssert(region1 === region3)
    }

    // TODO: move to RegionTests
    func testRelativeYPosition() {
        let region = Region()
        region.proximalBoundary = 200
        region.distalBoundary = 500
        XCTAssertNotNil(region.getRelativeYPosition(y: 300))
        XCTAssertEqual(region.getRelativeYPosition(y: 300)!, 0.3333, accuracy: 0.001)
    }
}
