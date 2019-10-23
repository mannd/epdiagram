//
//  Mark.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

// We import UIKit here and elsewhere to use CGFloat and avoid conversions
// of Double to CGFloat.
import UIKit

//  See this attempt at a ladder diagram program, the only one I can find: https://epfellow.wordpress.com/2010/11/04/electrocardiogram-ecgekg-ladder-diagrams/


/// A mark is a line segment, defined by its two end points.  Marks may slant in different directions, depending on the origin of an impulse.  So rather than using origin and terminus (which could swap positions if the slant of the mark is changed), we use the same convention as with regions: the two ends are termed *proximal* and *distal*.i
struct MarkPosition {
    var proximal: CGPoint
    var distal: CGPoint
}

/**
 The mark is a fundamental component of a ladder diagram.

 A mark can be many things, which makes the concept difficult to pin down.  It can be conduction through a region, with or without decrement.  Conduction can originate  in a region, at the top, bottom, or somewhere in the middle, or may originate in another region.  A mark can block or conduct. It can reenter, spawning another mark.
*/
class Mark {
    /// Draw a solid or dashed line when drawing a mark.
    enum LineStyle {
        case solid
        case dashed
    }

    /** Highlight is used in association with cursors and selecting marks.
     origin - high
     */
    enum Highlight {
        case proximal
        case distal
        case all
        case selected
        case none
    }

    /// Whether cursor is shown and if so is linked to the origin or terminus of thef mark, or to the mark as a whole (positional).
    enum CursorType {
        case proximal
        case distal
        case all
        case none
    }

    /// If a mark is an impulse origin and properties indicate show this, a dot of some sort with appear at the origin of the mark.
    var isImpulseOrigin: Bool = false
    var position: MarkPosition

    // TODO: Need to support multiple selection and copy features from one mark to a group of selected marks.
    var hasCursor: Bool = false
    var attached: Bool = false
    var cursorType: CursorType = .none
    var highlight: Highlight = .none
    // Anchor point for movement and to attach a cursor
    var anchor: Anchor = .none

    convenience init() {
        self.init(MarkPosition(proximal: CGPoint.zero, distal: CGPoint.zero))
    }

    init(_ position: MarkPosition) {
        self.position = position
    }

}
