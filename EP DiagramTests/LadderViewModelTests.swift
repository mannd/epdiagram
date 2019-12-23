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
        let location: CGFloat = 134.56
        let scale: CGFloat = 1.78
        let offset: CGFloat = 333.45
        let absoluteLocation = Common.translateToAbsolutePositionX(positionX: location, offset: offset, scale: scale)
        let relativeLocation = Common.translateToRelativePositionX(positionX: absoluteLocation, offset: offset, scale: scale)
        XCTAssertEqual(location, relativeLocation, accuracy: 0.0001)
    }

    func testLadderViewModelUnitHeight() {
        ladderViewModel.ladder = Ladder.defaultLadder()
        ladderViewModel.height = 100
        let height = ladderViewModel.getRegionUnitHeight(ladder: ladderViewModel.ladder)
        XCTAssertEqual(height, 16.6666, accuracy: 0.0001)
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

}
