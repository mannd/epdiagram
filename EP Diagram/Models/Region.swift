//
//  Region.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

// The two parts of a region.
enum RegionSection {
    case labelSection
    case markSection
}

/// All regions are divided into three parts...
enum RegionDivision {
    case proximal
    case middle
    case distal
    case none
}

// A Region is a collection of Marks, in left to right order.  Positions are
// vertical, i.e. Y axis.  A Region has a labelSection such as "A" or "AV" and
// a markSection.
class Region {
    var proximalBoundary: CGFloat = 0
    var distalBoundary: CGFloat = 0
    var selected: Bool = false
    var name: String = ""
    var marks: [Mark] = []
    var markable: Bool = true
    var height: CGFloat { get { return distalBoundary - proximalBoundary } }
    var unitHeight: Int = 1  // 1 = smallest region height, used to calculate actual height

    func appendMark(_ mark: Mark) {
        marks.append(mark)
    }

    func getRelativeYPosition(y: CGFloat) -> CGFloat? {
        guard y >= proximalBoundary && y <= distalBoundary else { return nil }
        return (y - proximalBoundary) / (distalBoundary - proximalBoundary)
    }

    // Two functions to use while moving marks to see is we are close to another mark
    // for purposes of highlighting them for connection.
    func getMarkProximalXPositions() -> [CGFloat] {
        var points: [CGFloat] = []
        for mark in marks {
            points.append(mark.segment.proximal.x)
        }
        return points
    }

    func getMarkDistalXPositions() -> [CGFloat] {
        var points: [CGFloat] = []
        for mark in marks {
            points.append(mark.segment.distal.x)
        }
        return points
    }

}
