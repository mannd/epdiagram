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

    override func setUp() {
        super.setUp()
        ladderView = LadderView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 100, height: 100)))
    }

    override func tearDown() {
        ladderView = nil
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
        ladderView.ladderViewHeight = 100
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
        region.proximalBoundary = 0
        region.distalBoundary = 300
        let regionSegment = Transform.toRegionSegment(scaledViewSegment: markPosition, region: region, offsetX: offset, scale: scale)
        let scaledViewSegment = Transform.toScaledViewSegment(regionSegment: regionSegment, region: region, offsetX: offset, scale: scale)
        XCTAssertEqual(markPosition.proximal.x, scaledViewSegment.proximal.x, accuracy: 0.0001)
        XCTAssertEqual(markPosition.proximal.y, scaledViewSegment.proximal.y, accuracy: 0.0001)
        XCTAssertEqual(markPosition.distal.x, scaledViewSegment.distal.x, accuracy: 0.001)
        XCTAssertEqual(markPosition.distal.y, scaledViewSegment.distal.y, accuracy: 0.001)
    }

    func testActiveRegion() {
        guard let activeRegion = ladderView.activeRegion else { XCTFail("activeRegion shouldn't be nil"); return }
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



    }
}
