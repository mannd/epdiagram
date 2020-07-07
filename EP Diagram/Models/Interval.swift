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
        for i in 0..<sortedMarks.count {
            if i + 1 < sortedMarks.count {
                // Only have region boundary spanning marks generate intervals.  Also remember mark segments can extend outside regions, though those segments are not shown.
                var interval = Interval()
                if (sortedMarks[i].segment.proximal.y <= 0 && sortedMarks[i+1].segment.proximal.y <= 0) {
                    // abs() not needed here since marks are sorted and i+1 thus > i.
                    interval.proximalValue = sortedMarks[i+1].segment.proximal.x - sortedMarks[i].segment.proximal.x
                    interval.proximalBoundary = (sortedMarks[i].segment.proximal.x, sortedMarks[i+1].segment.proximal.x)
                }
                if (sortedMarks[i].segment.distal.y >= 1 && sortedMarks[i+1].segment.distal.y >= 1) {
                    interval.distalValue = sortedMarks[i+1].segment.distal.x - sortedMarks[i].segment.distal.x
                    interval.distalBoundary = (sortedMarks[i].segment.distal.x, sortedMarks[i+1].segment.distal.x)
                }
                if interval.proximalValue != nil || interval.distalValue != nil {
                    intervals.append(interval)
                }
            }
        }
        return intervals
    }
}