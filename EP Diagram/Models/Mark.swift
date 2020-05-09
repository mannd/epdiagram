//
//  Mark.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

// See this attempt at a ladder diagram program, the only one I can find: https://epfellow.wordpress.com/2010/11/04/electrocardiogram-ecgekg-ladder-diagrams/

// We import UIKit here and elsewhere to use CGFloat and avoid conversions
// of Double to CGFloat.
import UIKit
import os.log

// We make it easy to normalize the y value of a point to be between 0 and 1.
extension CGPoint {
    func normalized() -> CGPoint {
        return CGPoint(x: self.x, y: self.y < 0 ? 0 : self.y > 1.0 ? 1.0 : self.y)
    }
}

// A line segment represented by 2 points.
struct Segment: Equatable {
    var proximal: CGPoint
    var distal: CGPoint

    func normalized() -> Segment {
        return Segment(proximal: proximal.normalized(), distal: distal.normalized())
    }

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

// TODO: redundant with Cursor.Direction, use that instead.
enum Movement {
    case horizontal
    case omnidirectional
}

typealias MarkSet = Set<Mark>

// A mark may have up to three attachments to marks in the proximal and distal regions
// and in its own region, i.e. reentry spawning a mark.
struct MarkGroup {
    var proximal: MarkSet = []
    var middle: MarkSet = []
    var distal: MarkSet = []

    var allMarks: MarkSet {
        get {
            proximal.union(middle.union(distal))
        }
    }

    mutating func remove(mark: Mark) {
        proximal.remove(mark)
        middle.remove(mark)
        distal.remove(mark)
    }

    var count: Int { allMarks.count }

    func highLight(highlight: Mark.Highlight) {
        for mark in allMarks {
            mark.highlight = highlight
        }
    }
}

extension Mark: Hashable, CustomDebugStringConvertible {
    var debugDescription: String {
        return "Mark ID " + id.debugDescription
    }

    static func == (lhs: Mark, rhs: Mark) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// The mark is a fundamental component of a ladder diagram.
class Mark {
    /// Draw a solid or dashed line when drawing a mark.
    enum LineStyle {
        case solid
        case dashed
        case dotted
    }

    // Highlight is used to show state of a mark visibly.
    enum Highlight {
        case attached // cursor attached
        case grouped // mark attached to cursor and 
        case selected
        case linked
        case none
    }

    // Site of block
    enum Block {
        case proximal
        case distal
        case none
    }

    // Site of impulse origin
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
    var width: CGFloat {
        get {
            return abs(segment.proximal.x - segment.distal.x)
        }
    }
    var length: CGFloat {
        get {
            return sqrt(pow((segment.proximal.x - segment.distal.x), 2) + pow((segment.proximal.y - segment.distal.y), 2))
        }
    }


    var attached: Bool = false // cursor attached and shown
    var selected: Bool = false // mark is selected for some action
    var highlight: Highlight = .none

    // Anchor point for movement and to attach a cursor
    var anchor: Anchor
    var lineStyle: LineStyle = .solid

    var block: Block = .none
    var impulseOrigin: ImpulseOrigin = .none

    var groupedMarks: MarkGroup

    let id: UUID // each mark as a unique id

    init(segment: Segment) {
        self.segment = segment
        self.id = UUID()
        groupedMarks = MarkGroup()
        anchor = .middle
    }

    convenience init() {
        self.init(segment: Segment(proximal: CGPoint.zero, distal: CGPoint.zero))
    }

    // init a mark that is vertical and spans a region.
    convenience init(positionX: CGFloat) {
        let segment = Segment(proximal: CGPoint(x: positionX, y: 0), distal: CGPoint(x: positionX, y:1.0))
        self.init(segment: segment)
    }

    deinit {
        os_log("Mark deinitied", log: OSLog.debugging, type: .debug)
    }

    /// Return midpoint of mark as CGPoint
    func midpoint() -> CGPoint {
        let segment = self.segment.normalized()
        let x = (segment.distal.x - segment.proximal.x) / 2.0 + segment.proximal.x
        let y = (segment.distal.y - segment.proximal.y) / 2.0 + segment.proximal.y
        return CGPoint(x: x, y: y)
    }

    func swapEnds() {
        let tmp = segment.proximal
        segment.proximal = segment.distal
        segment.distal = tmp
    }

    func getAnchorPosition() -> CGPoint {
        let anchorPosition: CGPoint
        switch anchor {
        case .distal:
            anchorPosition = segment.distal.normalized()
        case .middle:
            anchorPosition = midpoint()
        case .proximal:
            anchorPosition = segment.proximal.normalized()
        case .none:
            anchorPosition = segment.proximal.normalized()
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
