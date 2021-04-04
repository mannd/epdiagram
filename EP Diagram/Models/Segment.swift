//
//  Segment.swift
//  EP Diagram
//
//  Created by David Mann on 8/19/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

/// A line segment represented by 2 points.
struct Segment: Codable, Equatable {
    static let minLength: CGFloat = 0.2

    var proximal: CGPoint
    var distal: CGPoint

    var midpoint: CGPoint {
        CGPoint(x: (proximal.x + distal.x) / 2.0, y: (proximal.y + distal.y) / 2.0)
    }

    var length: CGFloat {
        sqrt(pow((proximal.x - distal.x), 2) + pow((proximal.y - distal.y), 2))
    }

    /// Clamp y coordinate  between 0 and 1.
    func normalized() -> Segment {
        return Segment(proximal: proximal.clampY(), distal: distal.clampY())
    }

    /// Get x coordinate on segment, knowing endpoints and y coordinate.
    ///
    /// See https://math.stackexchange.com/questions/149333/calculate-third-point-with-two-given-point
    /// - Parameter y: y coordinate to intercept the segment
    /// - Returns: x coordinate of intercept point, `nil` if no intercepti
    func getX(fromY y: CGFloat) -> CGFloat? {
        let x0 = proximal.x
        let x1 = distal.x
        let y0 = proximal.y
        let y1 = distal.y
        // Avoid getting close to dividing by zero.
        guard abs(y1 - y0) > 0.001 else { return nil }
        // Give up if y is not along segment.
        guard y < max(y1, y0) && y > min(y1, y0) else { return nil }
        return ((x1 - x0) * (y - y0)) / (y1 - y0) + x0
    }
}


