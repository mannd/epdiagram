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

    func maxXPoint() -> CGPoint {
        if proximal.x >= distal.x {
            return proximal
        }
        return distal
    }

    func maxX() -> CGFloat {
        return max(proximal.x, distal.x)
    }

    func maxY() -> CGFloat {
        return max(proximal.y, distal.y)
    }

    func minX() -> CGFloat {
        return min(proximal.x, distal.x)
    }

    func minY() -> CGFloat {
        return min(proximal.y, distal.y)
    }
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

    /** Highlight is used in association with cursors, selecting marks, and showing connections
     origin - high
     */
    // TODO: This might not work because we need prox/distal highlights and selection at the same time.
    enum Highlight {
        case proximal
        case distal
        case all
        case selected
        case none
    }

    /// If a mark is an impulse origin and properties indicate show this, a dot of some sort with appear at the origin of the mark.
    var isImpulseOrigin: Bool = false
    var position: MarkPosition {
        didSet {
            // set linked marks' positions
            PRINT("Did set a mark position")
        }
    }

    // TODO: Need to support multiple selection and copy features from one mark to a group of selected marks.
    var hasCursor: Bool = false
    var attached: Bool = false
    var highlight: Highlight = .none
    // Set when one end or another of a mark is close enough to connect
    var potentiallyConnected = false
    // Anchor point for movement and to attach a cursor
    var anchor: Anchor = .none
    var lineStyle: LineStyle = .solid

    // A mark may have up to three attachments to marks in the proximal and distal regions
    // and in its own region, i.e. rentry spawning a mark.
    struct AttachedMarks {
        var proximal: Mark?
        var middle: Mark?
        var distal: Mark?
    }
    var attachedMarks: AttachedMarks

    init(_ position: MarkPosition) {
        self.position = position
        attachedMarks = AttachedMarks(proximal: nil, middle: nil, distal: nil)
    }

    convenience init() {
        self.init(MarkPosition(proximal: CGPoint.zero, distal: CGPoint.zero))
    }

    // init a mark that is vertical and spans a region.
    convenience init(positionX: CGFloat) {
        let position = MarkPosition(proximal: CGPoint(x: positionX, y: 0), distal: CGPoint(x: positionX, y:1.0))
        self.init(position)
    }

    /// Return midpoint of mark as CGPoint
    func midpoint() -> CGPoint {
        let x = (position.distal.x - position.proximal.x) / 2.0 + position.proximal.x
        let y = (position.distal.y - position.proximal.y) / 2.0 + position.proximal.y
        return CGPoint(x: x, y: y)
    }


}
