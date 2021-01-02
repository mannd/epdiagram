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
        for region: Region in ladder.regions {
            assert(ladder.getIndex(ofRegion: region)! >= 0, String(format: "region %@ index negative, = %d", region.name, ladder.getIndex(ofRegion: region)!))
        }
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
        let mark = ladder.addMark(at: 100, inRegion: ladder.regions[0])
        XCTAssertEqual(mark?.segment.proximal.x, 100)
    }

    func testAddMarkNoActiveRegion() {
        let mark = ladder.addMark(at: 100, inRegion: nil)
        XCTAssertEqual(mark?.segment.proximal.x, nil)
    }

    func testGetRegionIndex() {
        let region = ladder.regions[1]
        XCTAssertEqual(ladder.getIndex(ofRegion: region), 1)
        XCTAssert(ladder.getRegionAfter(region: region) == ladder.regions[2])
        XCTAssert(ladder.getRegionBefore(region: region) == ladder.regions[0])
        let regionBefore = ladder.getRegionBefore(region: region)
        XCTAssertNil(ladder.getRegionBefore(region: regionBefore!))
        let regionAfter = ladder.getRegionAfter(region: region)
        XCTAssertNil(ladder.getRegionAfter(region: regionAfter!))
    }

    func testRegionIndicesUniqueInLadder() {
        var lastIndex = 0
        for region in ladder.regions {
            XCTAssert(ladder.getIndex(ofRegion: region) == lastIndex)
            lastIndex += 1
        }
    }

    func testRegionsEqual() {
        let region1 = ladder.regions[0]
        let region2 = ladder.regions[1]
        XCTAssert(!(region1 == region2))
        let region3 = region1
        XCTAssert(region1 == region3)
    }

    func testHasMarks() {
        XCTAssertEqual(false, ladder.hasMarks())
        let segment: Segment = Segment(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: 0, y: 1))
        let mark = ladder.addMark(fromSegment: segment, inRegion: ladder.regions[0])
        XCTAssertEqual(true, ladder.hasMarks())
        ladder.deleteMark(mark, inRegion: ladder.regions[0])
        XCTAssertEqual(false, ladder.hasMarks())
        // Make sure delete does nothing if mark or region is nil.
        let mark1 = ladder.addMark(fromSegment: segment, inRegion: ladder.regions[0])
        XCTAssertEqual(true, ladder.hasMarks())
        ladder.deleteMark(mark1, inRegion: nil)
        XCTAssertEqual(true, ladder.hasMarks())
        ladder.deleteMark(nil, inRegion: ladder.regions[0])
        XCTAssertEqual(true, ladder.hasMarks())
        ladder.deleteMark(mark1, inRegion: ladder.regions[0])
        XCTAssertEqual(false, ladder.hasMarks())
        ladder.addMark(fromSegment: segment, inRegion: ladder.regions[0])
        ladder.addMark(fromSegment: segment, inRegion: ladder.regions[0])
        ladder.addMark(fromSegment: segment, inRegion: ladder.regions[1])
        ladder.addMark(fromSegment: segment, inRegion: ladder.regions[1])
        XCTAssertEqual(true, ladder.hasMarks())
        ladder.deleteMarksInRegion(ladder.regions[0])
        XCTAssertEqual(true, ladder.hasMarks())
        ladder.deleteMarksInRegion(ladder.regions[1])
        XCTAssertEqual(false, ladder.hasMarks())
        ladder.addMark(fromSegment: segment, inRegion: ladder.regions[0])
        ladder.addMark(fromSegment: segment, inRegion: ladder.regions[0])
        ladder.addMark(fromSegment: segment, inRegion: ladder.regions[1])
        ladder.addMark(fromSegment: segment, inRegion: ladder.regions[1])
        XCTAssertEqual(true, ladder.hasMarks())
        ladder.clear()
        XCTAssertEqual(false, ladder.hasMarks())
    }

    func testToggleAnchor() {
        let ladder = Ladder.defaultLadder()
        let mark = ladder.addMark(Mark(), toRegion: ladder.regions[0])
        XCTAssertEqual(Anchor.middle, mark?.anchor)
        ladder.toggleAnchor(mark: mark)
        XCTAssertEqual(Anchor.proximal, mark?.anchor)
        ladder.toggleAnchor(mark: mark)
        XCTAssertEqual(Anchor.distal, mark?.anchor)
        ladder.toggleAnchor(mark: mark)
        XCTAssertEqual(Anchor.middle, mark?.anchor)
        ladder.toggleAnchor(mark: mark)
        XCTAssertEqual(Anchor.proximal, mark?.anchor)
        mark?.anchor = .none
        XCTAssertEqual(Anchor.none, mark?.anchor)
        ladder.toggleAnchor(mark: mark)
        XCTAssertEqual(Anchor.middle, mark?.anchor)
    }

    func testMoveGroupedMarks() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 100, y: 1)))
        ladder.registerMark(mark)
        let distalMark = Mark(segment: Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 200, y: 1)))
        ladder.registerMark(distalMark)
        ladder.addMark(mark, toRegion: ladder.regions[0])
        ladder.addMark(distalMark, toRegion: ladder.regions[1])
        mark.groupedMarkIds.distal.insert(distalMark.id)
        distalMark.groupedMarkIds.proximal.insert(mark.id)
        mark.anchor = .middle
        mark.move(movement: .horizontal, to: CGPoint(x: 200, y: 0))
        XCTAssertEqual(mark.segment, Segment(proximal: CGPoint(x: 200, y: 0), distal: CGPoint(x: 200, y: 1)))
        XCTAssertEqual(distalMark.segment, Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 200, y: 1)))
        ladder.moveGroupedMarks(forMark: mark)
        XCTAssertEqual(distalMark.segment, Segment(proximal: CGPoint(x: 200, y: 0), distal: CGPoint(x: 200, y: 1)))
        distalMark.anchor = .middle
        distalMark.move(movement: .horizontal, to: CGPoint(x: 300, y: 0))
        XCTAssertEqual(distalMark.segment, Segment(proximal: CGPoint(x: 300, y: 0), distal: CGPoint(x: 300, y: 1)))
        ladder.moveGroupedMarks(forMark: distalMark)
        XCTAssertEqual(mark.segment, Segment(proximal: CGPoint(x: 200, y: 0), distal: CGPoint(x: 300, y: 1)))
    }

    func testGetMarkGroup() {
        let mark1 = Mark()
        let mark2 = Mark()
        let mark3 = Mark()
        ladder.registerMark(mark1)
        ladder.registerMark(mark2)
        ladder.registerMark(mark3)
        var mig = MarkIdGroup()
        mig.proximal.insert(mark1.id)
        mig.middle.insert(mark2.id)
        mig.distal.insert(mark3.id)
        let mg = ladder.getMarkGroup(fromMarkIdGroup: mig)
        XCTAssert(mg.proximal.contains(mark1))
        XCTAssert(mg.middle.contains(mark2))
        XCTAssert(mg.distal.contains(mark3))
        XCTAssert(mg.count == 3)
    }
}
