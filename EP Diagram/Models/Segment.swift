//
//  Segment.swift
//  EP Diagram
//
//  Created by David Mann on 8/19/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

// A line segment represented by 2 points.
struct Segment: Codable, Equatable {
    var proximal: CGPoint
    var distal: CGPoint

    // Y axis is clamped between 0 and 1.
    func normalized() -> Segment {
        return Segment(proximal: proximal.clampY(), distal: distal.clampY())
    }
}


