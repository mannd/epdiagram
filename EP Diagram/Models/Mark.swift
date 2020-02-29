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
struct Segment {
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
        case dotted
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

    enum Block {
        case proximal
        case distal
        case none
    }

    enum ImpulseOrigin {
        case proximal
        case distal
        case none
    }

    var segment: Segment

    // Useful to detect marks that are too tiny to keep.
    var height: CGFloat {
        get {
            return abs(segment.proximal.y - segment.distal.y)
        }
    }
    var length: CGFloat {
        get {
            return sqrt(pow((segment.proximal.x - segment.distal.x), 2) + pow((segment.proximal.y - segment.distal.y), 2))
        }
    }


    // TODO: Need to support multiple selection and copy features from one mark to a group of selected marks.
    var attached: Bool = false
    var highlight: Highlight = .none
    // Set when one end or another of a mark is close enough to connect, or when there is a chain of marks.
    var potentiallyConnected = false
    // Anchor point for movement and to attach a cursor
    var anchor: Anchor
    var lineStyle: LineStyle = .solid

    var block: Block = .none
    var impulseOrigin: ImpulseOrigin = .none

    // A mark may have up to three attachments to marks in the proximal and distal regions
    // and in its own region, i.e. rentry spawning a mark.
    struct AttachedMarks {
        var proximal: [Mark] = []
        var middle: [Mark] = []
        var distal: [Mark] = []
    }
    
    var attachedMarks: AttachedMarks

    init(_ segment: Segment) {
        self.segment = segment
        attachedMarks = AttachedMarks()
        // Default anchor for new marks is middle.
        anchor = .middle
    }

    convenience init() {
        self.init(Segment(proximal: CGPoint.zero, distal: CGPoint.zero))
    }

    // init a mark that is vertical and spans a region.
    convenience init(positionX: CGFloat) {
        let position = Segment(proximal: CGPoint(x: positionX, y: 0), distal: CGPoint(x: positionX, y:1.0))
        self.init(position)
    }

    /// Return midpoint of mark as CGPoint
    func midpoint() -> CGPoint {
        let x = (segment.distal.x - segment.proximal.x) / 2.0 + segment.proximal.x
        let y = (segment.distal.y - segment.proximal.y) / 2.0 + segment.proximal.y
        return CGPoint(x: x, y: y)
    }

    func swapEnds() {
        let tmp = segment.proximal
        segment.proximal = segment.distal
        segment.distal = tmp
    }

    func getAnchorPositionX() -> CGFloat {
        let anchorPositionX: CGFloat
        switch anchor {
        case .distal:
            anchorPositionX = segment.distal.x
        case .middle:
            anchorPositionX = midpoint().x
        case .proximal:
            anchorPositionX = segment.proximal.x
        case .none:
            anchorPositionX = segment.proximal.x
        }
        return anchorPositionX
    }

    func getAnchorPositionY() -> CGFloat {
        let anchorPositionY: CGFloat
        switch anchor {
        case .distal:
            anchorPositionY = segment.distal.y
        case .middle:
            anchorPositionY = midpoint().y
        case .proximal:
            anchorPositionY = segment.proximal.y
        case .none:
            anchorPositionY = segment.proximal.y
        }
        return anchorPositionY
    }

    func getAnchorPosition() -> CGPoint {
        let anchorPosition: CGPoint
        switch anchor {
        case .distal:
            anchorPosition = segment.distal
        case .middle:
            anchorPosition = midpoint()
        case .proximal:
            anchorPosition = segment.proximal
        case .none:
            anchorPosition = segment.proximal
        }
        return anchorPosition
    }

    // Note point must be in absolute coordiates, with y between 0 and 1 relative to region height.
    func distance(point: CGPoint) -> CGFloat {
        var numerator = (segment.distal.y - segment.proximal.y) * point.x - (segment.distal.x - segment.proximal.x) * point.y + segment.distal.x * segment.proximal.y - segment.distal.y * segment.proximal.x
        numerator = abs(numerator)
        var denominator = pow((segment.distal.y - segment.proximal.y), 2) + pow((segment.distal.x - segment.proximal.x), 2)
        denominator = sqrt(denominator)
        return numerator / denominator
    }
}
