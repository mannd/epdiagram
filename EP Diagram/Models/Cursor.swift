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
    // TODO: CursorState probably will not be used.  Set to null for now.
    enum CursorState: String, Codable {
        case attached
        case unattached
        case null
    }

    // TODO: Use direction to implement cursors that change x vs y.
    // Vertical cursor is vertical and changes x, horizontal changes y position.
    enum Direction: String, Codable {
        case vertical
        case horizontal
    }

    /// Attachment point for the cursor on a mark.  If there is not attached mark, then this is ignored.
    enum Anchor: String, Codable {
        case proximal
        case middle
        case distal
        case none
    }

    /// Cursors have one dimensional positions along the x or y axis depending on their direction.
    var position: CGFloat

    var anchor = Anchor.middle
    var visible = false
    var direction = Direction.vertical

    // Touches +/- accuracy count as touches.
    let accuracy: CGFloat = 20
    
    init(positionX: CGFloat) {
        self.position = positionX
    }

    convenience override init() {
        self.init(positionX: 0)
    }

    func isNearCursor(point p: CGPoint) -> Bool {
        return abs(p.x - position) < accuracy
    }

    func move(delta: CGFloat) {
        position += delta
    }
}
