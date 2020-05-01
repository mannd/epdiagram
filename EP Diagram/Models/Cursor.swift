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
    var positionX: CGFloat // the horizontal position of the cursor using cursor view coordinates
    var positionOmniCircleY: CGFloat // point along omnidirectional cursor where circle is shown
    var maxPositionOmniCircleY: CGFloat // lowest point on screen where circle can be draw
    var markIntersectionPositionY: CGFloat // the end point and thus intersection point with the attached mark

    var anchor = Anchor.middle
    var visible = false
    var movement = Movement.horizontal

    // Touches +/- accuracy count as touches.
    let accuracy: CGFloat = 20
    
    init(positionX: CGFloat) {
        self.positionX = positionX
        self.positionOmniCircleY = 100 // this is a reasonable default value
        self.maxPositionOmniCircleY = 0 // this will be calculated by cursor view
        self.markIntersectionPositionY = 0
    }


    convenience override init() {
        self.init(positionX: 0)
    }

    func isNearCursor(point p: CGPoint) -> Bool {
        return abs(p.x - positionX) < accuracy
    }

    func move(delta: CGPoint) {
        positionX += delta.x
        if positionOmniCircleY < maxPositionOmniCircleY {
            positionOmniCircleY += delta.y
        }
    }
}
