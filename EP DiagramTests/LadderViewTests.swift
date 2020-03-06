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
        ladderView = LadderView()
    }

    override func tearDown() {
        ladderView = nil
        super.tearDown()
    }

    func testTranslateCoordinates() {
        let positionX: CGFloat = 134.56
        ladderView.scale = 1.78
        ladderView.offsetX = 333.45
        let absolutePositionX = ladderView.translateToRegionPositionX(scaledViewPositionX: positionX)
        let relativeLocation = ladderView.translateToScaledViewPositionX(regionPositionX: absolutePositionX)
        XCTAssertEqual(positionX, relativeLocation, accuracy: 0.0001)
    }

    func testLadderViewModelUnitHeight() {
        ladderView.ladder = Ladder.defaultLadder()
        ladderView.height = 100
        let height = ladderView.getRegionUnitHeight(ladder: ladderView.ladder)
        XCTAssertEqual(height, 20, accuracy: 0.0001)
    }

    // Pass scale and offset to ladderViewModel.
    func testScaleAndContent() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let sut = sb.instantiateViewController(withIdentifier: String(describing: ViewController.self)) as! ViewController
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
        let region = Region()
        region.proximalBoundary = 0
        region.distalBoundary = 300
        let absolutePosition = Common.translateToRegionSegment(scaledViewSegment: markPosition, region: region, offsetX: offset, scale: scale)
        let relativePosition = Common.translateToScaledViewSegment(regionSegment: absolutePosition, region: region, offsetX: offset, scale: scale)
        XCTAssertEqual(markPosition.proximal.x, relativePosition.proximal.x, accuracy: 0.0001)
        XCTAssertEqual(markPosition.proximal.y, relativePosition.proximal.y, accuracy: 0.0001)
        XCTAssertEqual(markPosition.distal.x, relativePosition.distal.x, accuracy: 0.001)
        XCTAssertEqual(markPosition.distal.y, relativePosition.distal.y, accuracy: 0.001)
    }
}
