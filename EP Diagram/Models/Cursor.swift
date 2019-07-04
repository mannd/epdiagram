//
//  Cursor.swift
//  EP Diagram
//
//  Created by David Mann on 6/3/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

// Cursor is a vertical line that is used to move and set Marks.
// It is also used to calibrate: a Cursor is set at the beginning and end
// of a known interval (1000 msec ideally).  Note that calibration is not
// necessary to draw ladder diagrams.
class Cursor: NSObject {
//    var color: UIColor?
//    var width: CGFloat?
//    var linkedMark: Mark?
    // The x coordinate of the cursor.
    var location: CGFloat
    var grabbed = false
    var offset: CGFloat = 0
    var scale: CGFloat = 1

    // Touches +/- 40 points count as touches.
    let differential: CGFloat = 40
    
    init(location: CGFloat) {
        self.location = location
    }

    convenience override init() {
        self.init(location: 0)
    }

    func isNearCursor(point p: CGPoint) -> Bool {
        return abs(p.x - location) < differential
    }

    func move(delta: CGPoint) {
        location += delta.x
    }
}
