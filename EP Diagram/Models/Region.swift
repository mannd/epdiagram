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
// a markSection.  Region boundaries are set by the calling ScaledView.
class Region: Codable, Equatable {
    var template: RegionTemplate
    var name: String { template.name }
    var description: String { template.description }
    var unitHeight: Int { template.unitHeight }
    var proximalBoundary: CGFloat = 0
    var distalBoundary: CGFloat = 0
    var activated: Bool = false
    var marks = [Mark]()
    var markable: Bool = true
    var height: CGFloat { distalBoundary - proximalBoundary }

    let id = UUID()

    init(template: RegionTemplate) {
        self.template = template
    }

    static func == (lhs: Region, rhs: Region) -> Bool {
        return lhs.id == rhs.id
    }

    func appendMark(_ mark: Mark) {
        marks.append(mark)
        // TODO: need to get add Interval to this mark, and hook previous interval to this mark.
        /* Thus
         Mark -- Interval -- nil
         Mark -- Interval -- Mark -- Interval -- nil
         etc.
         Thus each Mark has an Interval attached to it, an each Interval has at least one Mark (the prior Mark),
         with possibly another Mark after it.
         Must deal with deleted Marks and Marks added  in between Marks.

         See https://stackoverflow.com/questions/45340536/get-next-or-previous-item-to-an-object-in-a-swift-collection-or-array

         Consider an Array of [Any] (must use Any for structs, AnyObject is for classes only).
         Problem is the Array of Marks is not ordered, but in the order that the Marks are added.  So above won't
         work.  It looks like we will need to sort the Mark array based on proximal and distal x and add intervals
         on the fly in each region.  Only need to do with each addition and deletion and only in the affected region.
         */
//        let sortedMarks = marks.sort 
    }

    func getRelativeYPosition(y: CGFloat) -> CGFloat? {
        guard y >= proximalBoundary && y <= distalBoundary else { return nil }
        return (y - proximalBoundary) / (distalBoundary - proximalBoundary)
    }

    // Two functions to use while moving marks to see is we are close to another mark
    // for purposes of highlighting them for connection.
    func getMarkProximalXPositions() -> [CGFloat] {
        var points = [CGFloat]()
        for mark in marks {
            points.append(mark.segment.proximal.x)
        }
        return points
    }

    func getMarkDistalXPositions() -> [CGFloat] {
        var points = [CGFloat]()
        for mark in marks {
            points.append(mark.segment.distal.x)
        }
        return points
    }

}
