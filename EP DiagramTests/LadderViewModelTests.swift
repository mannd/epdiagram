//
//  LadderViewModelTests.swift
//  EP DiagramTests
//
//  Created by David Mann on 7/21/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import XCTest
@testable import EP_Diagram

class LadderViewModelTests: XCTestCase {
    private var ladderViewModel: LadderViewModel!

    override func setUp() {
        super.setUp()
        ladderViewModel = LadderViewModel()
    }

    override func tearDown() {
        ladderViewModel = nil
        super.tearDown()
    }

    func testTranslateCoordinates() {
        let positionX: CGFloat = 134.56
        let scale: CGFloat = 1.78
        let offset: CGFloat = 333.45
        let absolutePositionX = Common.translateToAbsolutePositionX(positionX: positionX, offset: offset, scale: scale)
        let relativeLocation = Common.translateToRelativePositionX(positionX: absolutePositionX, offset: offset, scale: scale)
        XCTAssertEqual(positionX, relativeLocation, accuracy: 0.0001)
    }

    func testLadderViewModelUnitHeight() {
        ladderViewModel.ladder = Ladder.defaultLadder()
        ladderViewModel.height = 100
        let height = ladderViewModel.getRegionUnitHeight(ladder: ladderViewModel.ladder)
        XCTAssertEqual(height, 20, accuracy: 0.0001)
    }

    // Pass scale and offset to ladderViewModel.
    func testScaleAndContent() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let sut = sb.instantiateViewController(withIdentifier: String(describing: ViewController.self)) as! ViewController
        sut.loadViewIfNeeded()
        let ladderView = sut.ladderView
        ladderView!.scale = 2.5
        ladderView!.offset = 305
        XCTAssertEqual(ladderView!.ladderViewModel.scale, 2.5)
        XCTAssertEqual(ladderView!.ladderViewModel.offset, 305)
    }

    func testMoreCoordinateTranslations() {
        let markPosition: MarkPosition = MarkPosition(proximal: CGPoint(x: 543.21, y: 99), distal: CGPoint(x: 329.8, y: 55.4))
        let scale: CGFloat = 1.78
        let offset: CGFloat = 333.45
        let rect: CGRect = CGRect(x: 0, y: 0, width: 800, height: 300)
        let absolutePosition = Common.translateToAbsoluteMarkPosition(markPosition: markPosition, inRect: rect, offsetX: offset, scale: scale)
        let relativePosition = Common.translateToRelativeMarkPosition(markPosition: absolutePosition, inRect: rect, offsetX: offset, scale: scale)
        XCTAssertEqual(markPosition.proximal.x, relativePosition.proximal.x, accuracy: 0.0001)
        XCTAssertEqual(markPosition.proximal.y, relativePosition.proximal.y, accuracy: 0.0001)
        XCTAssertEqual(markPosition.distal.x, relativePosition.distal.x, accuracy: 0.001)
        XCTAssertEqual(markPosition.distal.y, relativePosition.distal.y, accuracy: 0.001)
    }

}
