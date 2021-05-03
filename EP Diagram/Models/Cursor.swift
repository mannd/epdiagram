//
//  Cursor.swift
//  EP Diagram
//
//  Created by David Mann on 6/3/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import Foundation

// Cursor is a vertical line that is used to move and set Marks.
final class Cursor  {
    static let intersectionRadius: CGFloat = 5
    static let omniCircleRadius: CGFloat = 20
    private let omniCircleMargin: CGFloat = 25 // how close circle gets to top and bottom of cursor
    
    var positionX: CGFloat // the horizontal position of the cursor using cursor view coordinates
    var positionOmniCircleY: CGFloat // point along omnidirectional cursor where circle is shown
    var markIntersectionPositionY: CGFloat // the end point and thus intersection point with the attached mark

    var anchor = Anchor.middle
    var visible = false
    var movement = Movement.horizontal

    init(positionX: CGFloat) {
        self.positionX = positionX
        self.positionOmniCircleY = 100 // this is a reasonable default value
        self.markIntersectionPositionY = 0
    }

    convenience init() {
        self.init(positionX: 0)
    }

    func isNearCursor(point p: CGPoint, accuracy: CGFloat) -> Bool {
        return abs(p.x - positionX) < accuracy
    }

    func move(delta: CGPoint) {
        positionX += delta.x
        positionOmniCircleY += delta.y
        if positionOmniCircleY > markIntersectionPositionY - omniCircleMargin {
            positionOmniCircleY = markIntersectionPositionY - omniCircleMargin
        }
        if positionOmniCircleY < omniCircleMargin {
            positionOmniCircleY = omniCircleMargin
        }
    }
}
