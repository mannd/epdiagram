//
//  CGPoint+clampY.swift
//  EP Diagram
//
//  Created by David Mann on 8/19/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

// Clamp the y axis between min and max (default 0 and 1).
extension CGPoint {
    func clampY(min: CGFloat = 0, max: CGFloat = 1) -> CGPoint {
        if (min > max) {
            preconditionFailure("clampedY() min and max reversed")
        }
        return CGPoint(x: self.x, y: self.y < min ? min : self.y > max ? max: self.y)
    }
}

extension CGPoint {
    static func distanceBetweenPoints(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let diffX = p1.x - p2.x
        let diffY = p1.y - p2.y
        return sqrt(diffX * diffX + diffY * diffY)
    }
}

