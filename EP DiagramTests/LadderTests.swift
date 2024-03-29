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
            assert(ladder.index(ofRegion: region)! >= 0, String(format: "region %@ index negative, = %d", region.name, ladder.index(ofRegion: region)!))
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
        XCTAssertEqual(ladder.regionCount, 3)
    }

    func testDefaultRegionMarks() {
        for region in ladder.regions {
            // default ladder has no marks
            XCTAssertEqual(region.marks.count, 0)
        }
    }

    func testAddMark() {
        let mark = ladder.addMark(at: 100, toRegion: ladder.regions[0])
        XCTAssertNotNil(mark)
        XCTAssertEqual(mark.segment.proximal.x, 100)
        let mark2 = ladder.addMark(fromSegment: Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 200, y: 1.0)), toRegion: ladder.region(atIndex: 0))
        XCTAssertEqual(mark2.segment.proximal.x, 100)
        XCTAssertEqual(mark2.segment.distal.x, 200)
        XCTAssertEqual(mark2.segment.proximal.y, 0)
        XCTAssertEqual(mark2.segment.distal.y, 1.0)
    }

    func testGetRegionIndex() {
        let region = ladder.regions[1]
        XCTAssertEqual(ladder.index(ofRegion: region), 1)
        XCTAssert(ladder.regionAfter(region: region) == ladder.regions[2])
        XCTAssert(ladder.regionBefore(region: region) == ladder.regions[0])
        let regionBefore = ladder.regionBefore(region: region)
        XCTAssertNil(ladder.regionBefore(region: regionBefore!))
        let regionAfter = ladder.regionAfter(region: region)
        XCTAssertNil(ladder.regionAfter(region: regionAfter!))
    }

    func testRegionIndicesUniqueInLadder() {
        var lastIndex = 0
        for region in ladder.regions {
            XCTAssert(ladder.index(ofRegion: region) == lastIndex)
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
        let mark = ladder.addMark(fromSegment: segment, toRegion: ladder.regions[0])
        XCTAssertEqual(true, ladder.hasMarks())
        ladder.deleteMark(mark)
        XCTAssertEqual(false, ladder.hasMarks())
        // Make sure delete does nothing if mark is nil.
        let mark1 = ladder.addMark(fromSegment: segment, toRegion: ladder.regions[0])
        XCTAssertEqual(true, ladder.hasMarks())
        ladder.deleteMark(mark1)
        XCTAssertEqual(false, ladder.hasMarks())
        ladder.addMark(fromSegment: segment, toRegion: ladder.regions[0])
        ladder.addMark(fromSegment: segment, toRegion: ladder.regions[0])
        ladder.addMark(fromSegment: segment, toRegion: ladder.regions[1])
        ladder.addMark(fromSegment: segment, toRegion: ladder.regions[1])
        XCTAssertEqual(true, ladder.hasMarks())
        ladder.deleteMarksInRegion(ladder.regions[0])
        XCTAssertEqual(true, ladder.hasMarks())
        ladder.deleteMarksInRegion(ladder.regions[1])
        XCTAssertEqual(false, ladder.hasMarks())
        ladder.addMark(fromSegment: segment, toRegion: ladder.regions[0])
        ladder.addMark(fromSegment: segment, toRegion: ladder.regions[0])
        ladder.addMark(fromSegment: segment, toRegion: ladder.regions[1])
        ladder.addMark(fromSegment: segment, toRegion: ladder.regions[1])
        XCTAssertEqual(true, ladder.hasMarks())
        let all = ladder.allMarks()
        for mark in all {
            ladder.deleteMark(mark)
        }
        XCTAssertEqual(false, ladder.hasMarks())
    }

    func testToggleAnchor() {
        let ladder = Ladder.defaultLadder()
        let mark = ladder.addMark(Mark(), toRegion: ladder.regions[0])
        XCTAssertEqual(Anchor.middle, mark.anchor)
        ladder.toggleAnchor(mark: mark)
        XCTAssertEqual(Anchor.proximal, mark.anchor)
        ladder.toggleAnchor(mark: mark)
        XCTAssertEqual(Anchor.distal, mark.anchor)
        ladder.toggleAnchor(mark: mark)
        XCTAssertEqual(Anchor.middle, mark.anchor)
        ladder.toggleAnchor(mark: mark)
        XCTAssertEqual(Anchor.proximal, mark.anchor)
        ladder.toggleAnchor(mark: mark)
        XCTAssertEqual(Anchor.distal, mark.anchor)
    }

    func testMoveLinkedMarks() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 100, y: 1)))
        ladder.registerMark(mark)
        let distalMark = Mark(segment: Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 200, y: 1)))
        ladder.registerMark(distalMark)
        ladder.addMark(mark, toRegion: ladder.regions[0])
        ladder.addMark(distalMark, toRegion: ladder.regions[1])
        mark.linkedMarkIDs.distal.insert(distalMark.id)
        distalMark.linkedMarkIDs.proximal.insert(mark.id)
        mark.anchor = .middle
        mark.move(movement: .horizontal, to: CGPoint(x: 200, y: 0))
        XCTAssertEqual(mark.segment, Segment(proximal: CGPoint(x: 200, y: 0), distal: CGPoint(x: 200, y: 1)))
        XCTAssertEqual(distalMark.segment, Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 200, y: 1)))
        ladder.moveLinkedMarks(forMark: mark)
        XCTAssertEqual(distalMark.segment, Segment(proximal: CGPoint(x: 200, y: 0), distal: CGPoint(x: 200, y: 1)))
        distalMark.anchor = .middle
        distalMark.move(movement: .horizontal, to: CGPoint(x: 300, y: 0))
        XCTAssertEqual(distalMark.segment, Segment(proximal: CGPoint(x: 300, y: 0), distal: CGPoint(x: 300, y: 1)))
        ladder.moveLinkedMarks(forMark: distalMark)
        XCTAssertEqual(mark.segment, Segment(proximal: CGPoint(x: 200, y: 0), distal: CGPoint(x: 300, y: 1)))
    }

    func testLinkedMarks() {
        let mark1 = Mark()
        let mark2 = Mark()
        let mark3 = Mark()
        ladder.registerMark(mark1)
        ladder.registerMark(mark2)
        ladder.registerMark(mark3)
        #if USECLASSES
        let mig = LinkedMarkIDs()
        #else
        var mig = LinkedMarkIDs()
        #endif
        mig.proximal.insert(mark1.id)
        mig.middle.insert(mark2.id)
        mig.distal.insert(mark3.id)
        let mg = ladder.getLinkedMarksFromLinkedMarkIDs(mig)
        XCTAssert(mg.proximal.contains(mark1))
        XCTAssert(mg.middle.contains(mark2))
        XCTAssert(mg.distal.contains(mark3))
        XCTAssert(mg.count == 3)
    }

    func testMarkIndexing() {
        let mark = Mark()
        XCTAssertEqual(mark.regionIndex, -1)
        ladder.addMark(mark, toRegion: ladder.regions[0])
        XCTAssertEqual(mark.regionIndex, 0)
        let mark2 = ladder.addMark(at: 10, toRegion: ladder.regions[1])
        XCTAssertEqual(mark2.regionIndex, 1)
        let segment = Segment(proximal: CGPoint.zero, distal: CGPoint.zero)
        let mark3 = ladder.addMark(fromSegment: segment, toRegion: ladder.regions[0])
        XCTAssertEqual(mark3.regionIndex, 0)
        // test region(atIndex:) function
        ladder.addMark(mark, toRegion: ladder.region(atIndex: 0))
        XCTAssertEqual(mark.regionIndex, 0)
        ladder.addMark(mark, toRegion: ladder.region(atIndex: 1))
        XCTAssertEqual(mark.regionIndex, 1)
    }

    func testFreshLadder() {
        ladder.addMark(Mark(), toRegion: ladder.region(atIndex: 0))
        let newLadder = Ladder.freshLadder(fromLadder: ladder)
        XCTAssertEqual(newLadder.regions.count, ladder.regions.count)
        XCTAssertEqual(ladder.regions[0].marks.count, 1)
        XCTAssertEqual(newLadder.regions[0].marks.count, 0)
    }

    func testNormalizeRegions() {
        ladder.setAllRegionsWithMode(.selected)
        for region in ladder.regions {
            XCTAssertEqual(region.mode, .selected)
        }
        ladder.normalizeRegions()
        for region in ladder.regions {
            XCTAssertEqual(region.mode, .normal)
        }
    }

    func testHaveDifferentRegions() {
        let mark1 = ladder.addMark(Mark(), toRegion: ladder.region(atIndex: 0))
        let mark2 = ladder.addMark(Mark(), toRegion: ladder.region(atIndex: 0))
        var marks: [Mark] = [mark1, mark2]
        XCTAssertFalse(ladder.marksAreInDifferentRegions(marks))
        let mark3 = ladder.addMark(Mark(), toRegion: ladder.region(atIndex: 1))
        marks.append(mark3)
        XCTAssertTrue(ladder.marksAreInDifferentRegions(marks))
    }

    func testMarksAreNotContiguous() {
        let mark1 = ladder.addMark(Mark(), toRegion: ladder.region(atIndex: 0))
        let mark2 = ladder.addMark(Mark(), toRegion: ladder.region(atIndex: 1))
        let marks: [Mark] = [mark1, mark2]
        XCTAssertTrue(ladder.marksAreNotContiguous(marks))
        ladder.deleteMark(mark1)
        ladder.deleteMark(mark2)
        XCTAssertTrue(ladder.marksAreNotContiguous(marks))
        let mark3 = ladder.addMark(at: 100, toRegion: ladder.region(atIndex: 0))
        let mark4 = ladder.addMark(at: 200, toRegion: ladder.region(atIndex: 0))
        let marks2 = [mark3, mark4]
        XCTAssertFalse(ladder.marksAreNotContiguous(marks2))
        let _ = ladder.addMark(at: 150, toRegion: ladder.region(atIndex: 0))
        XCTAssertTrue(ladder.marksAreNotContiguous(marks2))
        let mark5 = ladder.addMark(at: 5, toRegion: ladder.region(atIndex: 1))
        let _ = ladder.addMark(at: 10, toRegion: ladder.region(atIndex: 1))
        let mark7 = ladder.addMark(at: 15, toRegion: ladder.region(atIndex: 1))
        let marks3 = [mark5, mark7]
        XCTAssertTrue(ladder.marksAreNotContiguous(marks3))
    }

    func testMeanCL() {
        let mark1 = ladder.addMark(at: 100, toRegion: ladder.region(atIndex: 0))
        let mark2 = ladder.addMark(at: 200, toRegion: ladder.region(atIndex: 0))
        let mark3 = ladder.addMark(at: 400, toRegion: ladder.region(atIndex: 0))
        let marks = [mark1, mark2, mark3]
        XCTAssertEqual(ladder.meanCL(marks), 150, accuracy: 0.0001)
    }

    func testAttachedMark() {
        let mark1 = ladder.addMark(at: 100, toRegion: ladder.region(atIndex: 0))
        let mark2 = ladder.addMark(at: 200, toRegion: ladder.region(atIndex: 0))
        ladder.attachedMark = mark1
        XCTAssertEqual(mark1.mode, .attached)
        ladder.attachedMark = nil
        XCTAssertEqual(mark1.mode, .normal)
        ladder.attachedMark = mark1
        XCTAssertEqual(mark1.mode, .attached)
        ladder.attachedMark = mark2
        XCTAssertEqual(mark1.mode, .normal)
        XCTAssertEqual(mark2.mode, .attached)
    }

    func testAllMarks() {
        let mark1 = ladder.addMark(at: 100, toRegion: ladder.region(atIndex: 0))
        let mark2 = ladder.addMark(at: 200, toRegion: ladder.region(atIndex: 1))
        let mark3 = ladder.addMark(at: 400, toRegion: ladder.region(atIndex: 2))
        let allMarks = ladder.allMarks()
        XCTAssertEqual(allMarks, [mark1, mark2, mark3])
    }

    func testLinkedMarkIDs() {
        let mark1 = ladder.addMark(at: 100, toRegion: ladder.region(atIndex: 0))
        let mark2 = ladder.addMark(at: 100, toRegion: ladder.region(atIndex: 1))
        mark1.linkedMarkIDs.distal.insert(mark2.id)
        XCTAssertEqual(mark1.linkedMarkIDs.distal.first, mark2.id)
        XCTAssertEqual(mark1.linkedMarkIDs.distal.count, 1)
        ladder.unlinkAllMarks()
        XCTAssertEqual(mark1.linkedMarkIDs.distal.count, 0)
        mark1.linkedMarkIDs.distal.insert(mark2.id)
        XCTAssertEqual(mark1.linkedMarkIDs.distal.count, 1)
        // linkedMarkIDs are structs, i.e. value semantics, so copies are independent of original.
        #if USECLASSES
        let linkedMarkIDs = mark1.linkedMarkIDs
        #else
        var linkedMarkIDs = mark1.linkedMarkIDs
        #endif
        linkedMarkIDs.remove(id: mark2.id)
        XCTAssertEqual(linkedMarkIDs.count, 0)
        // if linkedMarkIDs are a struct, the commented out statement is true
        #if USECLASSES
        XCTAssertEqual(mark1.linkedMarkIDs.distal.count, 0)
        #else
        XCTAssertEqual(mark1.linkedMarkIDs.distal.count, 1)
        #endif
        mark1.linkedMarkIDs = linkedMarkIDs
        XCTAssertEqual(mark1.linkedMarkIDs.distal.count, 0)
    }

    func testRegistryConcept() {
        // Updating struct as part of a class in a dict doesn't work == but it does per below??
        XCTAssertEqual(ladder.debugGetRegistry().count, 0)
        let mark1 = ladder.addMark(at: 100, toRegion: ladder.region(atIndex: 0))
        XCTAssertEqual(ladder.debugGetRegistry().count, 1)
        let mark2 = ladder.addMark(at: 100, toRegion: ladder.region(atIndex: 1))
        XCTAssertEqual(mark1.linkedMarkIDs.count, 0)
        mark1.linkedMarkIDs.distal.insert(mark2.id)
        XCTAssertEqual(mark1.linkedMarkIDs.count, 1)
        let testMark = ladder.debugGetRegistry()[mark1.id]
        XCTAssertEqual(testMark?.linkedMarkIDs.count, 1)
        XCTAssertEqual(testMark?.linkedMarkIDs.distal.contains(mark2.id), true)
        ladder.unlinkAllMarks()
        XCTAssertEqual(testMark?.linkedMarkIDs.count, 0)
        XCTAssertEqual(mark1.linkedMarkIDs.count, 0)
        XCTAssertEqual(mark2.linkedMarkIDs.count, 0)

        mark1.linkedMarkIDs.distal.insert(mark2.id)

        #if USECLASSES
        let linkedMarkIDs = ladder.debugGetRegistry()[mark1.id]?.linkedMarkIDs
        #else
        var linkedMarkIDs = ladder.debugGetRegistry()[mark1.id]?.linkedMarkIDs
        #endif
        XCTAssertEqual(linkedMarkIDs?.count, 1)
        XCTAssertEqual(ladder.debugGetRegistry()[mark1.id]?.linkedMarkIDs.count, 1)
        linkedMarkIDs?.removeAll()
        XCTAssertEqual(linkedMarkIDs?.count, 0)
        #if USECLASSES
        XCTAssertEqual(ladder.debugGetRegistry()[mark1.id]?.linkedMarkIDs.count, 1)
        #else
        XCTAssertEqual(ladder.debugGetRegistry()[mark1.id]?.linkedMarkIDs.count, 1)
        #endif
    }
}
