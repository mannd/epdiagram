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

    /// Attachment point for the cursor on a mark.  If there is not attached mark, then this is ignored.
    enum Anchor: String, Codable {
        case proximal
        case middle
        case distal
        case none
    }

    /// The x coordinate of the cursor.
    var location: CGFloat

    var state = CursorState.null
    var anchor = Anchor.middle
    var visible = false

    // Touches +/- accuracy count as touches.
    let accuracy: CGFloat = 20
    
    init(location: CGFloat) {
        self.location = location
    }

    convenience override init() {
        self.init(location: 0)
    }

    func isNearCursor(point p: CGPoint) -> Bool {
        return abs(p.x - location) < accuracy
    }

    func move(delta: CGFloat) {
        location += delta
    }
}
