//
//  Interval.swift
//  EP Diagram
//
//  Created by David Mann on 7/4/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

struct Interval {
    typealias Boundary = (first: CGFloat?, second: CGFloat?)
    static let boundaryTolerance: CGFloat = 0.01 // how close to region boundary is considered to be at the boundary
    static let proximalLimit: CGFloat = 0 + boundaryTolerance
    static let distalLimit: CGFloat = 1 - boundaryTolerance
    var proximalBoundary: Boundary?
    var distalBoundary: Boundary?

    static func createIntervals(region: Region) -> [Interval] {
        var intervals = [Interval]()
        let sortedMarks = region.marks.sorted()
        let proximalSortedMarks = sortedMarks.filter { $0.segment.proximal.y <= proximalLimit }
        let distalSortedMarks = sortedMarks.filter { $0.segment.distal.y >= distalLimit }
        for i in 0..<proximalSortedMarks.count {
            if i + 1 < proximalSortedMarks.count {
                var interval = Interval()
                interval.proximalBoundary = (proximalSortedMarks[i].segment.proximal.x, proximalSortedMarks[i+1].segment.proximal.x)
                intervals.append(interval)
            }
        }
        for i in 0..<distalSortedMarks.count {
            if i + 1 < distalSortedMarks.count {
                var interval = Interval()
                interval.distalBoundary = (distalSortedMarks[i].segment.distal.x, distalSortedMarks[i+1].segment.distal.x)
                intervals.append(interval)
            }
        }
        return intervals
    }
}
