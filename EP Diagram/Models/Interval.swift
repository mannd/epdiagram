//
//  Interval.swift
//  EP Diagram
//
//  Created by David Mann on 7/4/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

// Intervals are generated on the fly and so don't need to conform to Codable.
struct Interval {
    typealias Boundary = (first: CGFloat?, second: CGFloat?)

    var proximalValue: CGFloat?
    var distalValue: CGFloat?
    var proximalBoundary: Boundary?
    var distalBoundary: Boundary?

    // Caller should do this on background thread.
    static func createIntervals(marks: [Mark]) -> [Interval] {
        var intervals = [Interval]()
        let sortedMarks = marks.sorted()
        let proximalSortedMarks = sortedMarks.filter { $0.segment.proximal.y <= 0 }
        let distalSortedMarks = sortedMarks.filter { $0.segment.distal.y >= 1 }
        for i in 0..<proximalSortedMarks.count {
            if i + 1 < proximalSortedMarks.count {
                var interval = Interval()
                interval.proximalValue = proximalSortedMarks[i+1].segment.proximal.x - proximalSortedMarks[i].segment.proximal.x
                interval.proximalBoundary = (proximalSortedMarks[i].segment.proximal.x, proximalSortedMarks[i+1].segment.proximal.x)

                if interval.proximalValue != nil {
                    intervals.append(interval)
                }
            }
        }
        for i in 0..<distalSortedMarks.count {
            if i + 1 < distalSortedMarks.count {
                var interval = Interval()
                interval.distalValue = distalSortedMarks[i+1].segment.distal.x - distalSortedMarks[i].segment.distal.x
                interval.distalBoundary = (distalSortedMarks[i].segment.distal.x, distalSortedMarks[i+1].segment.distal.x)
                if interval.distalValue != nil {
                    intervals.append(interval)
                }
            }
        }
        return intervals
    }
}
