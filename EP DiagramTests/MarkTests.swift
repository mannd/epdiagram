//
//  MarkTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 7/26/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class MarkTests: XCTestCase {
    let accuracy: CGFloat = 0.00001 // floating point accuracy

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMarkLocation() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 100, y: 1.0)))
        XCTAssertEqual(mark.segment.proximal.x, 100)
        XCTAssertEqual(mark.segment.distal.x, 100)
    }

    func testMarkHeight() {
        let mark = Mark(positionX: 0)
        XCTAssertEqual(mark.height, 1.0)
        let mark2 = Mark(segment: Segment(proximal: CGPoint(x: 1, y: 0.25), distal: CGPoint(x: 2, y: 0.75)))
        XCTAssertEqual(mark2.height, 0.5, accuracy: accuracy)
    }

    func testMarkLength() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x: 0.5, y: 0.8), distal: CGPoint(x: 0.9, y: 0.2)))
        XCTAssertEqual(mark.length, 0.721110255092798, accuracy: accuracy)
    }

    func testMarkDistanceToPoint() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x: 1, y: 0), distal: CGPoint(x: 1, y: 1)))
        let point = CGPoint(x: 1.5, y: 0.5)
        XCTAssertEqual(mark.distance(point: point), 0.5, accuracy: accuracy)
        let point2 = CGPoint(x: 1, y: 0.5)
        let mark2 = Mark(segment: Segment(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: 2, y: 1)))
        XCTAssertEqual(mark2.distance(point: point2), 0, accuracy: accuracy)
        let mark3 = Mark(segment: Segment(proximal: CGPoint(x: 1, y: 0.7), distal: CGPoint(x: 2, y: 0.9)))
        let point3 = CGPoint(x: 2, y: 0.7)
        XCTAssertEqual(mark3.distance(point: point3), 0.19612, accuracy: accuracy)
    }

    func testMidpoint() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x: 50, y: 0.21), distal: CGPoint(x:120, y: 0.88)))
        let region = Region(template: RegionTemplate())
        region.proximalBoundaryY = 100
        region.distalBoundaryY = 500
        let relativeMarkPosition = Transform.toScaledViewSegment(regionSegment: mark.segment, region: region, offsetX: 0, scale: 1)
        P("relativeMarkPosition = \(relativeMarkPosition)")
        let midPoint = relativeMarkPosition.midpoint
        XCTAssertEqual(midPoint, CGPoint(x: 85, y: 318))
        let anotherMarkPosition = Segment(proximal: CGPoint(x: -3, y: 5), distal: CGPoint(x: 8, y: -1))
        let anotherMidPoint = anotherMarkPosition.midpoint
        XCTAssertEqual(anotherMidPoint, CGPoint(x: 2.5, y: 2))
        let mark1 = Mark(segment: Segment(proximal: CGPoint.zero, distal: CGPoint(x: 100, y: 1)))
        let mark1MidPoint = mark1.midpoint()
        XCTAssertEqual(mark1MidPoint, CGPoint(x: 50, y: 0.5))
        XCTAssertEqual(mark1.midpointX(), 50)
    }

    func testNormalization() {
        let p1 = CGPoint(x: 1, y: 1.5)
        XCTAssertEqual(p1.clampY().y, 1.0, accuracy: accuracy)
        let p2 = CGPoint(x: 2, y: -1.5)
        XCTAssertEqual(p2.clampY().y, 0, accuracy: accuracy)
        let s1 = Segment(proximal: p1, distal: p2)
        let normalizedS1 = s1.normalized()
        XCTAssertEqual(normalizedS1.proximal.y, 1.0, accuracy: accuracy)
        XCTAssertEqual(normalizedS1.distal.y, 0, accuracy: accuracy)
        let p3 = CGPoint(x: 100, y: 0.7)
        XCTAssertEqual(p3.y, 0.7, accuracy: accuracy)
        XCTAssertEqual(p3.x, 100, accuracy: accuracy)
    }

    func testMarkSet() {
        let mark1 = Mark()
        let mark2 = Mark()
        let mark3 = Mark()
        #if USECLASSES
        let linkedMarks = LinkedMarks()
        #else
        var linkedMarks = LinkedMarks()
        #endif
        linkedMarks.proximal.insert(mark1)
        linkedMarks.middle.insert(mark2)
        linkedMarks.distal.insert(mark3)
        let allMarks = linkedMarks.allMarks
        XCTAssert(allMarks.count == 3, "should be 3 elements in allMarks")
        XCTAssert(allMarks.contains(mark1))
        XCTAssert(allMarks.contains(mark2))
        XCTAssert(allMarks.contains(mark3))

    }

    func testRegistry() {
        let ladder = Ladder.defaultLadder()
        let mark1 = Mark()
        ladder.addMark(mark1, toRegion: ladder.regions[0])
        let mark2 = Mark()
        ladder.addMark(mark2, toRegion: ladder.regions[1])
        let mark3 = Mark()
        ladder.addMark(mark3, toRegion: ladder.regions[2])
        XCTAssertEqual(ladder.lookup(id: mark1.id), mark1)
        XCTAssertEqual(ladder.lookup(id: mark2.id), mark2)
        XCTAssertEqual(ladder.lookup(id: mark3.id), mark3)
        ladder.deleteMark(mark1)
        XCTAssertEqual(ladder.lookup(id: mark1.id), nil)
    }

    func testAltLookup() {
        let ladder = Ladder.defaultLadder()
        let mark1 = Mark()
        ladder.addMark(mark1, toRegion: ladder.regions[0])
        let mark2 = Mark()
        ladder.addMark(mark2, toRegion: ladder.regions[1])
        let mark3 = Mark()
        ladder.addMark(mark3, toRegion: ladder.regions[2])
        XCTAssertEqual(ladder.altLookup(id: mark1.id), mark1)
        XCTAssertEqual(ladder.altLookup(id: mark2.id), mark2)
        XCTAssertEqual(ladder.altLookup(id: mark3.id), mark3)
        ladder.deleteMark(mark1)
        XCTAssertEqual(ladder.altLookup(id: mark1.id), nil)
    }

    func testRelativeRegions() {
        let ladder = Ladder.defaultLadder()
        let aMark = Mark()
        let avMark = Mark()
        let vMark = Mark()
        ladder.addMark(aMark, toRegion: ladder.regions[0])
        ladder.addMark(avMark, toRegion: ladder.regions[1])
        ladder.addMark(vMark, toRegion: ladder.regions[2])
        XCTAssertEqual(Ladder.regionRelationBetweenMarks(mark: aMark, otherMark: aMark), RegionRelation.same)
        XCTAssertEqual(Ladder.regionRelationBetweenMarks(mark: aMark, otherMark: avMark), RegionRelation.after)
        XCTAssertEqual(Ladder.regionRelationBetweenMarks(mark: avMark, otherMark: aMark), RegionRelation.before)
        XCTAssertEqual(Ladder.regionRelationBetweenMarks(mark: aMark, otherMark: vMark), RegionRelation.distant)
    }

    func testMovement() {
        let mark = Mark(segment: Segment(proximal: CGPoint.zero, distal: CGPoint.zero))
        mark.anchor = .middle
        mark.move(movement: .horizontal, to: CGPoint(x: 100, y: 0))
        XCTAssertEqual(mark.segment, Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 100, y: 0)))
        mark.anchor = .proximal
        mark.move(movement: .horizontal, to: CGPoint(x: 200, y: 1))
        XCTAssertEqual(mark.segment, Segment(proximal: CGPoint(x: 200, y: 0), distal: CGPoint(x: 100, y: 0)))
        mark.anchor = .distal
        mark.move(movement: .horizontal, to: CGPoint(x: 150, y: 0.5))
        XCTAssertEqual(mark.segment, Segment(proximal: CGPoint(x: 200, y: 0), distal: CGPoint(x: 150, y: 0)))
        mark.anchor = .middle
        mark.move(movement: .horizontal, to: CGPoint(x: 100, y: 0.5))
        XCTAssertEqual(mark.segment, Segment(proximal: CGPoint(x: 125, y: 0), distal: CGPoint(x: 75, y: 0)))
        mark.segment = Segment(proximal: CGPoint.zero, distal: CGPoint(x: 0, y: 1.0))
        mark.anchor = .middle
        mark.move(movement: .omnidirectional, to: CGPoint(x: 100, y: 0.5))
        XCTAssertEqual(mark.segment, Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 100, y: 1.0)))
        mark.move(movement: .omnidirectional, to: CGPoint(x: 100, y: 1.0))
        XCTAssertEqual(mark.segment, Segment(proximal: CGPoint(x: 100, y: 0.5), distal: CGPoint(x: 100, y: 1.5)))
        mark.anchor = .distal
        mark.move(movement: .omnidirectional, to: CGPoint(x: 100, y: 1.0))
        XCTAssertEqual(mark.segment, Segment(proximal: CGPoint(x: 100, y: 0.5), distal: CGPoint(x: 100, y: 1.0)))
        mark.anchor = .proximal
        mark.move(movement: .omnidirectional, to: CGPoint(x: 200, y: 1.0))
        XCTAssertEqual(mark.segment, Segment(proximal: CGPoint(x: 200, y: 1.0), distal: CGPoint(x: 100, y: 1.0)))
    }

    func testSwapEnds() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 200, y: 1)))
        mark.swapEnds()
        XCTAssertEqual(mark.segment.proximal, CGPoint(x: 200, y: 1))
        XCTAssertEqual(mark.segment.distal, CGPoint(x: 100, y: 0))
    }

    func testLinkedMarks() {
        #if USECLASSES
        let mg = LinkedMarks()
        #else
        var mg = LinkedMarks()
        #endif
        XCTAssertEqual(mg.count, 0)
        mg.proximal.insert(Mark())
        mg.middle.insert(Mark())
        let newMark = Mark()
        mg.distal.insert(newMark)
        XCTAssertEqual(mg.count, 3)
        mg.remove(mark: newMark)
        XCTAssertEqual(mg.count, 2)
        mg.setMode(.selected)
        let allMarks = mg.allMarks
        for mark in allMarks {
            XCTAssertEqual(mark.mode, .selected)
        }
    }

    func testLinkedMarkIDs() {
        #if USECLASSES
        let mig = LinkedMarkIDs()
        #else
        var mig = LinkedMarkIDs()
        #endif
        XCTAssertEqual(mig.count, 0)
        mig.proximal.insert(Mark().id)
        mig.middle.insert(Mark().id)
        let newMark = Mark()
        mig.distal.insert(newMark.id)
        XCTAssertEqual(mig.count, 3)
        mig.remove(id: newMark.id)
        XCTAssertEqual(mig.count, 2)
        mig.removeAll()
        XCTAssertEqual(mig.count, 0)
    }

    func testMarkDimensions() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: 100, y: 1)))
        XCTAssertEqual(mark.width, 100)
        XCTAssertEqual(mark.height, 1)
        XCTAssertEqual(mark.length, sqrt(10_001), accuracy: accuracy)
        // Do same for segments
        let segment = Segment(proximal: CGPoint(x: 0, y: 0), distal: CGPoint(x: 100, y: 1))
        XCTAssertEqual(segment.length, sqrt(10_001), accuracy: accuracy)

    }

    func testAnchorPosition() {
        let mark = Mark(segment: Segment(proximal: CGPoint.zero, distal: CGPoint(x: 0, y: 1)))
        // test default anchor position
        XCTAssertEqual(mark.anchor, .middle)
        XCTAssertEqual(mark.getAnchorPosition(), CGPoint(x: 0, y: 0.5))
        mark.anchor = .proximal
        XCTAssertEqual(mark.getAnchorPosition(), CGPoint(x: 0, y: 0))
        mark.anchor = .distal
        XCTAssertEqual(mark.getAnchorPosition(), CGPoint(x: 0, y: 1))
        let mark1 = Mark(segment: Segment(proximal: CGPoint(x: 320, y: 0.2), distal: CGPoint(x: 115, y: 0.7)))
        mark1.anchor = .proximal
        XCTAssertEqual(mark1.getAnchorPosition(), CGPoint(x: 320, y: 0.2))
        mark1.anchor = .distal
        XCTAssertEqual(mark1.getAnchorPosition(), CGPoint(x: 115, y: 0.7))
        mark1.anchor = .middle
        XCTAssertEqual(mark1.getAnchorPosition().x, 217.5, accuracy: accuracy)
        XCTAssertEqual(mark1.getAnchorPosition().y, 0.45, accuracy: accuracy)
    }

    func testLineStyles() {
        let mark = Mark()
        XCTAssertEqual(mark.style, .solid)
        XCTAssertEqual(mark.style.description, L("Solid"))
        mark.style = .dashed
        XCTAssertEqual(mark.style.description, L("Dashed"))
        mark.style = .dotted
        XCTAssertEqual(mark.style.description, L("Dotted"))
        XCTAssertEqual(mark.style.id, .dotted)
        mark.style = .inherited
        XCTAssertEqual(mark.style.description, L("Default"))
        XCTAssertEqual(mark.style.id, .inherited)
    }

    func testRightTriangleBase() {
        let height: CGFloat = 1.0
        var result = Geometry.rightTriangleBase(withAngle: 45, height: height)
        XCTAssertEqual(result, 1.0, accuracy: accuracy)
        result = Geometry.rightTriangleBase(withAngle: 30, height: height)
        XCTAssertEqual(result, 0.57735, accuracy: accuracy)
        result = Geometry.rightTriangleBase(withAngle: 0, height: height)
        XCTAssertEqual(result, 0, accuracy: accuracy)
    }

    func testMarkMode() {
        let ladder = Ladder.defaultLadder()
        ladder.addMark(Mark(), toRegion: ladder.regions[0])
        ladder.addMark(Mark(), toRegion: ladder.regions[1])
        ladder.addMark(Mark(), toRegion: ladder.regions[1])
        for region in ladder.regions {
            for mark in region.marks {
                XCTAssertEqual(mark.mode, .normal)
            }
        }
        ladder.setAllMarksWithMode(.attached)
        for region in ladder.regions {
            for mark in region.marks {
                XCTAssertEqual(mark.mode, .attached)
            }
        }
        let normalMarks = ladder.allMarksWithMode(.normal)
        XCTAssertEqual(normalMarks.count, 0)
        let attachedMarks = ladder.allMarksWithMode(.attached)
        XCTAssertEqual(attachedMarks.count, 3)
        let region1AttachedMarks = ladder.marksWithMode(.attached, inRegion: ladder.regions[1])
        XCTAssertEqual(region1AttachedMarks.count, 2)
    }

    func testEarliestPoint() {
        let mark1 = Mark(positionX: 100)
        // proximal wins if mark is vertical
        XCTAssertEqual(mark1.earliestPoint, mark1.segment.proximal)
        mark1.segment.distal = CGPoint(x: 110, y: 1.0)
        XCTAssertEqual(mark1.earliestPoint, mark1.segment.proximal)
        mark1.segment.distal = CGPoint(x: 90, y: 1.0)
        XCTAssertEqual(mark1.earliestPoint, mark1.segment.distal)
    }

    func testEarly() {
        let mark1 = Mark(positionX: 100)
        XCTAssertEqual(mark1.earlyEndpoint, .none)
        mark1.segment.distal = CGPoint(x: 110, y: 1.0)
        XCTAssertEqual(mark1.earlyEndpoint, .proximal)
        mark1.segment.distal = CGPoint(x: 90, y: 1.0)
        XCTAssertEqual(mark1.earlyEndpoint, .distal)
    }

    func testLate() {
        let mark1 = Mark(positionX: 100)
        XCTAssertEqual(mark1.lateEndpoint, .none)
        mark1.segment.distal = CGPoint(x: 110, y: 1.0)
        XCTAssertEqual(mark1.lateEndpoint, .distal)
        mark1.segment.distal = CGPoint(x: 90, y: 1.0)
        XCTAssertEqual(mark1.lateEndpoint, .proximal)
    }

    func testApplyAngle() {
        let mark = Mark(positionX: 0)
        mark.applyAngle(45)
        XCTAssertEqual(mark.segment.distal.x, 1.0, accuracy: 0.0001)
    }

    func testLinkiedMarkIDsInit() {
        let linkedMarkIDs = LinkedMarkIDs()
        XCTAssertEqual(linkedMarkIDs.count, 0)
    }

    func testMarkLabel() {
        XCTAssertNil(Mark.MarkLabel.defaultValue)
    }

    func testSwapAnchors() {
        let mark = Mark()
        XCTAssertEqual(mark.anchor, .middle)
        mark.swapAnchors()
        // middle anchor doesn't get swapped
        XCTAssertEqual(mark.anchor, .middle)
        mark.anchor = .proximal
        mark.swapAnchors()
        XCTAssertEqual(mark.anchor, .distal)
        mark.swapAnchors()
        XCTAssertEqual(mark.anchor, .proximal)
    }

    func testGetAnchorPosition() {
        let mark = Mark()
        XCTAssertEqual(mark.getAnchorPosition(), mark.midpoint())
        mark.anchor = .proximal
        XCTAssertEqual(mark.getAnchorPosition(), mark.segment.distal.clampY())
        mark.anchor = .distal
        XCTAssertEqual(mark.getAnchorPosition(), mark.segment.proximal.clampY())
    }

    func testClampY() {
        let point1 = CGPoint(x: 0, y: 1)
        XCTAssertEqual(point1.clampY(), point1)
        let point2 = CGPoint(x: 0, y: 0.5)
        XCTAssertEqual(point2.clampY(), point2)
        let point3 = CGPoint(x: 0.2, y: 0.5)
        XCTAssertEqual(point3.clampY(), point3)
        let point4 = CGPoint(x: 0, y: 1.5)
        XCTAssertEqual(point4.clampY(), point1)
        // Below will crash due to precondition failure.
        // let point5 = CGPoint(x: 0, y: 1)
        // XCTAssertEqual(point5.clampY(min: 1, max: 0), point5)
    }
}
