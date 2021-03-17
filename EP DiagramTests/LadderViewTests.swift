//
//  LadderViewTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 7/21/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class LadderViewTests: XCTestCase {
    private var ladderView: LadderView!
    private var cursorView: CursorView!

    override func setUp() {
        super.setUp()
        ladderView = LadderView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 100, height: 100)))
        cursorView = CursorView()
        ladderView.cursorViewDelegate = cursorView
        cursorView.ladderViewDelegate = ladderView
    }

    override func tearDown() {
        ladderView = nil
        cursorView = nil
        super.tearDown()
    }

    func testTranslateCoordinates() {
        let positionX: CGFloat = 134.56
        ladderView.scale = 1.78
        ladderView.offsetX = 333.45
        let regionPositionX = ladderView.transformToRegionPositionX(scaledViewPositionX: positionX)
        let scaledViewPositionX = ladderView.transformToScaledViewPositionX(regionPositionX: regionPositionX)
        XCTAssertEqual(positionX, scaledViewPositionX, accuracy: 0.0001)
    }

    func testLadderViewModelUnitHeight() {
        ladderView.ladder = Ladder.defaultLadder()
        ladderView.viewHeight = 100
        let height = ladderView.getRegionUnitHeight(ladder: ladderView.ladder)
        XCTAssertEqual(height, 20, accuracy: 0.0001)
    }

    // Pass scale and offset to ladderViewModel.
    func testScaleAndContent() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let sut = sb.instantiateViewController(withIdentifier: String(describing: DiagramViewController.self)) as! DiagramViewController
        sut.loadViewIfNeeded()
        let ladderView = sut.ladderView
        ladderView!.scale = 2.5
        ladderView!.offsetX = 305
        XCTAssertEqual(ladderView!.scale, 2.5)
        XCTAssertEqual(ladderView!.offsetX, 305)
    }

    func testMoreCoordinateTranslations() {
        let markPosition: Segment = Segment(proximal: CGPoint(x: 543.21, y: 99), distal: CGPoint(x: 329.8, y: 55.4))
        let scale: CGFloat = 1.78
        let offset: CGFloat = 333.45
        let region = Region(template: RegionTemplate())
        region.proximalBoundaryY = 0
        region.distalBoundaryY = 300
        let regionSegment = Transform.toRegionSegment(scaledViewSegment: markPosition, region: region, offsetX: offset, scale: scale)
        let scaledViewSegment = Transform.toScaledViewSegment(regionSegment: regionSegment, region: region, offsetX: offset, scale: scale)
        XCTAssertEqual(markPosition.proximal.x, scaledViewSegment.proximal.x, accuracy: 0.0001)
        XCTAssertEqual(markPosition.proximal.y, scaledViewSegment.proximal.y, accuracy: 0.0001)
        XCTAssertEqual(markPosition.distal.x, scaledViewSegment.distal.x, accuracy: 0.001)
        XCTAssertEqual(markPosition.distal.y, scaledViewSegment.distal.y, accuracy: 0.001)
    }

    func testActiveRegion() {
        guard let activeRegion = ladderView.activeRegion else {
            XCTFail("activeRegion shouldn't be nil"); return
        }
        XCTAssertEqual(activeRegion, ladderView.ladder.regions[0])
        XCTAssertEqual(activeRegion.mode, Region.Mode.active)
        XCTAssertEqual(ladderView.ladder.regions[1].mode, .normal)
        // make sure only 1 active region at a time
        ladderView.activeRegion = ladderView.ladder.regions[1]
        XCTAssertEqual(ladderView.ladder.regions[0].mode, .normal)
        XCTAssertEqual(ladderView.ladder.regions[1].mode, .active)
        ladderView.activeRegion = nil
        XCTAssertEqual(ladderView.ladder.regions[0].mode, .normal)
        XCTAssertEqual(ladderView.ladder.regions[1].mode, .normal)
        ladderView.setActiveRegion(regionNum: 0)
        XCTAssertEqual(ladderView.ladder.regions[0].mode, .active)
        XCTAssertEqual(ladderView.ladder.regions[1].mode, .normal)
        ladderView.saveState()
        ladderView.activeRegion = ladderView.ladder.regions[1]
        XCTAssertEqual(ladderView.ladder.regions[0].mode, .normal)
        XCTAssertEqual(ladderView.ladder.regions[1].mode, .active)
        ladderView.restoreState()
        XCTAssertEqual(ladderView.ladder.regions[0].mode, .active)
        XCTAssertEqual(ladderView.ladder.regions[1].mode, .normal)
        // Tapping active label should inactivate it
        ladderView.labelWasTapped(labelRegion: ladderView.ladder.regions[0])
        XCTAssertEqual(ladderView.ladder.regions[0].mode, .normal)
        XCTAssertEqual(ladderView.ladder.regions[1].mode, .normal)
        XCTAssertEqual(ladderView.activeRegion, nil)
        ladderView.labelWasTapped(labelRegion: ladderView.ladder.regions[1])
        XCTAssertEqual(ladderView.ladder.regions[0].mode, .normal)
        XCTAssertEqual(ladderView.ladder.regions[1].mode, .active)
        XCTAssertEqual(ladderView.activeRegion, ladderView.ladder.regions[1])
        // test setActiveRegion
        ladderView.setActiveRegion(regionNum: 0)
        XCTAssertEqual(ladderView.activeRegion, ladderView.ladder.region(atIndex: 0))
        XCTAssertEqual(ladderView.hasActiveRegion(), true)
        ladderView.activeRegion = nil
        XCTAssertEqual(ladderView.hasActiveRegion(), false)
    }

    func testNormalizeMarks() {
        ladderView.activeRegion = nil
        let mark1 = ladderView.addMarkToActiveRegion(regionPositionX: 0)
        XCTAssertNil(mark1)
        ladderView.activeRegion = ladderView.ladder.region(atIndex: 0)
        let mark2 = ladderView.addMarkToActiveRegion(regionPositionX: 10)
        let mark3 = Mark()
        ladderView.ladder.addMark(mark3, toRegion: ladderView.activeRegion!)
        XCTAssertNotNil(mark2)
        XCTAssertNotNil(mark3)
        mark2!.mode = Mark.Mode.attached
        mark3.mode = Mark.Mode.linked
        ladderView.normalizeAllMarks()
        XCTAssertEqual(mark2!.mode, .normal)
        XCTAssertEqual(mark3.mode, .normal)
    }

    func testDeleteSelectedMarks() {
        let mark1 = Mark()
        let mark2 = Mark()
        let mark3 = Mark()
        ladderView.ladder.addMark(mark1, toRegion: ladderView.ladder.region(atIndex: 0))
        ladderView.ladder.addMark(mark2, toRegion: ladderView.ladder.region(atIndex: 1))
        ladderView.ladder.addMark(mark3, toRegion: ladderView.ladder.region(atIndex: 0))
        mark1.mode = .selected
        var marksCount = ladderView.ladder.region(atIndex: 0).marks.count
        XCTAssertEqual(marksCount, 2)
        ladderView.deleteSelectedMarks()
        marksCount = ladderView.ladder.region(atIndex: 0).marks.count
        XCTAssertEqual(marksCount, 1)
        mark2.mode = .selected
        mark3.mode = .selected
        ladderView.deleteSelectedMarks()
        marksCount = ladderView.ladder.region(atIndex: 0).marks.count
        XCTAssertEqual(marksCount, 0)
        marksCount = ladderView.ladder.region(atIndex: 1).marks.count
        XCTAssertEqual(marksCount, 0)
    }

    func testDeleteAllInRegion() {
        ladderView.ladder.region(atIndex: 0).mode = .selected
        ladderView.ladder.activeRegion = ladderView.ladder.region(atIndex: 0)
        _ = ladderView.addMarkToActiveRegion(regionPositionX: 0)
        _ = ladderView.addMarkToActiveRegion(regionPositionX: 1)
        _ = ladderView.addMarkToActiveRegion(regionPositionX: 2)
        ladderView.ladder.activeRegion = ladderView.ladder.region(atIndex: 1)
        _ = ladderView.addMarkToActiveRegion(regionPositionX: 3)
        ladderView.ladder.region(atIndex: 0).mode = .selected
        var count = ladderView.ladder.region(atIndex: 0).marks.count
        XCTAssertEqual(count, 3)
        ladderView.deleteAllInSelectedRegion()
        count = ladderView.ladder.region(atIndex: 0).marks.count
        XCTAssertEqual(count, 0)
        ladderView.deleteAllInSelectedRegion()
        count = ladderView.ladder.region(atIndex: 1).marks.count
        XCTAssertEqual(count, 1)
        ladderView.ladder.region(atIndex: 1).mode = .selected
        ladderView.deleteAllInSelectedRegion()
        count = ladderView.ladder.region(atIndex: 1).marks.count
        XCTAssertEqual(count, 1)
        ladderView.normalizeRegions()
        // No selected region, so delete doesn't do anything
        _ = ladderView.addMarkToActiveRegion(regionPositionX: 4)
        ladderView.deleteAllInSelectedRegion()
        count = ladderView.ladder.region(atIndex: 1).marks.count
        XCTAssertEqual(count, 2)
        ladderView.ladder.region(atIndex: 1).mode = .selected
        ladderView.deleteAllInSelectedRegion()
        count = ladderView.ladder.region(atIndex: 1).marks.count
        XCTAssertEqual(count, 0)
    }

    func testAdjustCursor() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 100, y: 1)))
        ladderView.ladder.addMark(mark, toRegion: ladderView.ladder.regions[1])
        ladderView.adjustCursor(mark: mark)
        // cursor should move to mark positionX
        XCTAssertEqual(cursorView.isNearCursor(positionX: 100, accuracy: 0.001), true)
    }

    func testAssessCloseness() {
        let mark1 = Mark(positionX: 10)
        let mark2 = Mark(positionX: 15)
        ladderView.ladder.addMark(mark1, toRegion: ladderView.ladder.regions[0])
        ladderView.ladder.addMark(mark2, toRegion: ladderView.ladder.regions[1])
        var closeness = ladderView.assessCloseness(ofMark: mark1, toNeighboringMark: mark2, usingNearbyDistance: 4.9)
        XCTAssertFalse(closeness)
        closeness = ladderView.assessCloseness(ofMark: mark1, toNeighboringMark: mark2, usingNearbyDistance: 5.1)
        XCTAssertTrue(closeness)
        // a mark can't be assessed as close to itself
        XCTAssertFalse(ladderView.assessCloseness(ofMark: mark1, toNeighboringMark: mark1, usingNearbyDistance: 0))
        // test closeness of marks in same region
        let mark3 = Mark(segment: Segment(proximal: CGPoint(x: 12, y: 0), distal: CGPoint(x: 22, y: 0.5)))
        ladderView.ladder.addMark(mark3, toRegion: ladderView.ladder.regions[0])
        closeness = ladderView.assessCloseness(ofMark: mark1, toNeighboringMark: mark3, usingNearbyDistance: 3)
        XCTAssertTrue(closeness)
        // Parallel marks in same region should not link, so reject closeness
        let mark4 = Mark(positionX: 11)
        ladderView.ladder.addMark(mark4, toRegion: ladderView.ladder.regions[0])
        closeness = ladderView.assessCloseness(ofMark: mark1, toNeighboringMark: mark4, usingNearbyDistance: 2)
        XCTAssertFalse(closeness)
    }

    func testNearestAnchor() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x:100, y: 0), distal: CGPoint(x: 150, y: 1)))
        ladderView.ladder.addMark(mark, toRegion: ladderView.ladder.regions[0])
        var scaledPosition = ladderView.transformToScaledViewPosition(regionPosition: CGPoint(x: 101, y: 0), region: ladderView.ladder.regions[0])
        var anchor = ladderView.nearestAnchor(position: scaledPosition, mark: mark)
        XCTAssertEqual(anchor, .proximal)
        scaledPosition = ladderView.transformToScaledViewPosition(regionPosition: CGPoint(x: 152, y: 1), region: ladderView.ladder.regions[0])
        anchor = ladderView.nearestAnchor(position: scaledPosition, mark: mark)
        XCTAssertEqual(anchor, .distal)
        scaledPosition = ladderView.transformToScaledViewPosition(regionPosition: CGPoint(x: 125, y: 0.5), region: ladderView.ladder.regions[0])
        anchor = ladderView.nearestAnchor(position: scaledPosition, mark: mark)
        XCTAssertEqual(anchor, .middle)
    }

    func testUndoablyDeleteMark() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x:100, y: 0), distal: CGPoint(x: 150, y: 1)))
        ladderView.ladder.addMark(mark, toRegion: ladderView.ladder.regions[0])
        XCTAssertEqual(ladderView.ladder.regions[0].marks.count, 1)
        ladderView.undoablyDeleteMark(mark: mark)
        XCTAssertEqual(ladderView.ladder.regions[0].marks.count, 0)
        ladderView.redoablyUndeleteMark(mark: mark)
        XCTAssertEqual(ladderView.ladder.regions[0].marks.count, 1)
    }

    func testAnchorLadderViewPosition() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x:100, y: 0), distal: CGPoint(x: 100, y: 1)))
        ladderView.ladder.addMark(mark, toRegion: ladderView.ladder.regions[0])
        var anchorPosition = ladderView.anchorLadderViewPosition(ofMark: mark)
        let scaledMidpoint = ladderView.transformToScaledViewPosition(regionPosition: CGPoint(x: 100, y: 0.5), region: ladderView.ladder.regions[0])
        XCTAssertEqual(anchorPosition, scaledMidpoint)
        mark.anchor = .proximal
        anchorPosition = ladderView.anchorLadderViewPosition(ofMark: mark)
        let scaledProximalEndpoint = ladderView.transformToScaledViewPosition(regionPosition: CGPoint(x: 100, y: 0), region: ladderView.ladder.regions[0])
        XCTAssertEqual(anchorPosition, scaledProximalEndpoint)
        mark.anchor = .distal
        anchorPosition = ladderView.anchorLadderViewPosition(ofMark: mark)
        let scaledDistalEndpoint = ladderView.transformToScaledViewPosition(regionPosition: CGPoint(x: 100, y: 1), region: ladderView.ladder.regions[0])
        XCTAssertEqual(anchorPosition, scaledDistalEndpoint)
    }

    func testAnchorRegionPosition() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x:100, y: 0), distal: CGPoint(x: 100, y: 1)))
        ladderView.ladder.addMark(mark, toRegion: ladderView.ladder.regions[0])
        var anchorPosition = ladderView.anchorRegionPosition(ofMark: mark)
        XCTAssertEqual(anchorPosition, CGPoint(x: 100, y: 0.5))
        mark.anchor = .proximal
        anchorPosition = ladderView.anchorRegionPosition(ofMark: mark)
        XCTAssertEqual(anchorPosition, mark.segment.proximal)
        mark.anchor = .distal
        anchorPosition = ladderView.anchorRegionPosition(ofMark: mark)
        XCTAssertEqual(anchorPosition, mark.segment.distal)
    }

    func testSlantAngle() {
        let mark = Mark(segment: Segment(proximal: CGPoint(x:0, y: 0), distal: CGPoint(x: 100, y: 1)))
        ladderView.ladder.addMark(mark, toRegion: ladderView.ladder.regions[0])
        let height = ladderView.ladder.regions[0].height
        let calculatedAngle = atan(100 / height).radiansToDegrees
        let angle = ladderView.slantAngle(mark: mark, endpoint: .proximal)
        XCTAssertEqual(angle, calculatedAngle, accuracy: 0.0001)
        let angle2 = ladderView.slantAngle(mark: mark, endpoint: .distal)
        XCTAssertEqual(angle, -angle2, accuracy: 0.0001)
    }

    func testNoSelectionExists() {
        XCTAssertTrue(ladderView.noSelectionExists())
        let mark = Mark(segment: Segment(proximal: CGPoint(x:0, y: 0), distal: CGPoint(x: 100, y: 1)))
        ladderView.ladder.addMark(mark, toRegion: ladderView.ladder.regions[1])
        XCTAssertTrue(ladderView.noSelectionExists())
        ladderView.ladder.regions[0].mode = .selected
        XCTAssertFalse(ladderView.noSelectionExists())
        ladderView.ladder.regions[0].mode = .normal
        XCTAssertTrue(ladderView.noSelectionExists())
        mark.mode = .selected
        XCTAssertFalse(ladderView.noSelectionExists())
    }

    func testDominantStyleOfMarks() {
        let mark1 = Mark()
        let mark2 = Mark()
        let mark3 = Mark()
        var marks: [Mark] = [Mark]()
        XCTAssertNil(ladderView.dominantStyleOfMarks(marks: marks))
        marks.append(mark1)
        marks.append(mark2)
        marks.append(mark3)
        XCTAssertEqual(ladderView.dominantStyleOfMarks(marks: marks), .solid)
        mark1.style = .dashed
        mark2.style = .dashed
        mark3.style = .dashed
        XCTAssertEqual(ladderView.dominantStyleOfMarks(marks: marks), .dashed)
        mark1.style = .dotted
        XCTAssertNil(ladderView.dominantStyleOfMarks(marks: marks))
    }

    // TODO: move to calibration tests
    func testCalibration() {
        let calibration = Calibration()
        calibration.set(zoom: 1.0, calFactor: 100)
        ladderView.calibration = calibration
        var value = ladderView.formatValue(100, usingCalFactor: 1)
        XCTAssertEqual(value, 100)
        value = ladderView.formatValue(100, usingCalFactor: 10)
        XCTAssertEqual(value, 1000)
        value = ladderView.formatValue(100, usingCalFactor: 0.01)
        XCTAssertEqual(value, 1)
        let rawValue = ladderView.regionValueFromCalibratedValue(1, usingCalFactor: 0.01)
        XCTAssertEqual(rawValue, 100, accuracy: 0.0001)
    }

    func testGetRawValueFromInterval() {
        let interval: CGFloat = 100
        let calFactor: CGFloat = 10
        let rawValue = ladderView.regionValueFromCalibratedValue(interval, usingCalFactor: calFactor)
        XCTAssertEqual(rawValue, 10)
        let formattedValue = ladderView.formatValue(CGFloat(rawValue), usingCalFactor: calFactor)
        XCTAssertEqual(formattedValue, Int(interval))
        let calibration = Calibration()
        calibration.set(zoom: 1.0, calFactor: 10)
        ladderView.calibration = calibration
        let rawValue2 = ladderView.regionValueFromCalibratedValue(interval, usingCalFactor: calibration.currentCalFactor)
        XCTAssertEqual(rawValue2, 10)
        calibration.currentZoom = 2.0
        ladderView.offsetX = 10
        let rawValue3 = ladderView.regionValueFromCalibratedValue(interval, usingCalFactor: calibration.currentCalFactor)
        XCTAssertEqual(rawValue3, 20)
        let formattedValue2 = ladderView.formatValue(CGFloat(rawValue3), usingCalFactor: calibration.currentCalFactor)
        XCTAssertEqual(formattedValue2, Int(interval))
    }

    func testAddMark() {
        ladderView.activeRegion = nil
        XCTAssertNil(ladderView.addMarkToActiveRegion(regionPositionX: 100))
        XCTAssertNil(ladderView.addMarkToActiveRegion(scaledViewPositionX: 100))

        ladderView.activeRegion = ladderView.ladder.regions[0]
        XCTAssertNotNil(ladderView.addMarkToActiveRegion(regionPositionX: 100))
        XCTAssertNotNil(ladderView.addMarkToActiveRegion(scaledViewPositionX: 100))

    }

    func testAttachMark() {
        ladderView.activeRegion = ladderView.ladder.region(atIndex: 0)
        let mark1 = ladderView.addMarkToActiveRegion(regionPositionX: 100)
        let mark2 = ladderView.addMarkToActiveRegion(regionPositionX: 200)
        ladderView.attachMark(mark1)
        XCTAssertEqual(mark1!.mode, .attached)
        ladderView.unattachAttachedMark()
        XCTAssertEqual(mark1!.mode, .normal)
        ladderView.attachMark(mark1)
        XCTAssertEqual(mark1!.mode, .attached)
        // Can't have two marks attached at the same time.
        ladderView.attachMark(mark2)
        XCTAssertEqual(mark2!.mode, .attached)
        XCTAssertEqual(mark1!.mode, .normal)
    }

    func testAddAttachedMark() {
        ladderView.addAttachedMark(scaledViewPositionX: 100)
        let attachedMark = ladderView.ladder.attachedMark
        XCTAssertNotNil(attachedMark)
        XCTAssertEqual(attachedMark!.mode, .attached)
    }

    func testHighlightNearbyMarks() {
        let ladder = ladderView.ladder
        let mark1 = ladderView.ladder.addMark(at: 100, toRegion: ladder.regions[0])
        let mark2 = ladderView.ladder.addMark(at: 200, toRegion: ladder.regions[1])
        XCTAssertEqual(mark1.mode, .normal)
        XCTAssertEqual(mark2.mode, .normal)
        ladder.attachedMark = mark1
        XCTAssertEqual(mark1.mode, .attached)
        XCTAssertEqual(mark2.mode, .normal)
        ladder.normalizeAllMarksExceptAttachedMark()
        XCTAssertEqual(mark1.mode, .attached)
        XCTAssertEqual(mark2.mode, .normal)
        let mark3 = ladder.addMark(at: 100, toRegion: ladder.regions[1])
        var isClose = ladderView.assessCloseness(ofMark: mark1, toNeighboringMark: mark3, usingNearbyDistance: 1)
        XCTAssertTrue(isClose)
        isClose = ladderView.assessCloseness(ofMark: mark1, toNeighboringMark: mark2, usingNearbyDistance: 1)
        XCTAssertFalse(isClose)
        mark2.segment = Segment(proximal: CGPoint(x: 100, y: 0), distal: CGPoint(x: 200, y: 0.5))
        isClose = ladderView.assessCloseness(ofMark: mark1, toNeighboringMark: mark2, usingNearbyDistance: 1)
        XCTAssertTrue(isClose)
        XCTAssertEqual(mark1.mode, .attached)
        ladderView.highlightNearbyMarks(mark1)
        XCTAssertEqual(mark1.mode, .attached)

        XCTAssertEqual(mark2.mode, .linked)
        mark2.segment = Segment(proximal: CGPoint(x: 150, y: 0), distal: CGPoint(x: 200, y: 0.5))
        ladderView.highlightNearbyMarks(mark1)
        XCTAssertEqual(mark2.mode, .normal)
        XCTAssertEqual(mark1.mode, .attached)

    }

}
