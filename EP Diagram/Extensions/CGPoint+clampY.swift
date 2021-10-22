//
//  CGPoint+clampY.swift
//  EP Diagram
//
//  Created by David Mann on 8/19/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

extension CGPoint {
    /// Clamp the y axis between min and max (default 0 and 1).
    /// - Parameters:
    ///   - min: minimum Y value, default = 0
    ///   - max: maximum Y value, default = 1.0
    /// - Returns: CGPoint with Y value clamped
    func clampY(min: CGFloat = 0, max: CGFloat = 1) -> CGPoint {
        if (min > max) {
            preconditionFailure("clampedY() min and max reversed")
        }
        return CGPoint(x: self.x, y: self.y < min ? min : self.y > max ? max: self.y)
    }
}

extension CGPoint {
    /// Find shortest distance between two points
    /// - Parameters:
    ///   - p1: first point
    ///   - p2: second point
    /// - Returns: distance between the ooints as CGFloat
    static func distanceBetweenPoints(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let diffX = p1.x - p2.x
        let diffY = p1.y - p2.y
        return sqrt(diffX * diffX + diffY * diffY)
    }
}

