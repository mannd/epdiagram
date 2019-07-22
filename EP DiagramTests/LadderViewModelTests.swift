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
        let absoluteLocation = ladderViewModel.translateToAbsoluteLocation(location: location, offset: offset, scale: scale)
        let relativeLocation = ladderViewModel.translateToRelativeLocation(location: absoluteLocation, offset: offset, scale: scale)
        XCTAssertEqual(location, relativeLocation, accuracy: 0.0001)
    }

    func testLadderViewModelUnitHeight() {
        ladderViewModel.ladder = Ladder.defaultLadder()
        let height = ladderViewModel.getRegionUnitHeight(rect: CGRect(x: 0, y: 0, width: 0, height: 100), ladder: ladderViewModel.ladder)
        XCTAssertEqual(height, 16.6666, accuracy: 0.0001)
    }

}
