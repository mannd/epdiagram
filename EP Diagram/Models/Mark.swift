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

// MARK: - typealiases

typealias MarkSet = Set<Mark>
typealias MarkIdSet = Set<UUID>

// MARK: - enums

enum Movement {
    case horizontal
    case omnidirectional
}

// MARK: - classes

// FIXME: This is problematic, see below.  For solutions see https://www.behindmedia.com/2017/12/22/implementing-a-weakly-referencing-set-in-swift/, which implements a set of generic weak references.  More practical is https://stackoverflow.com/questions/43306110/remove-duplicate-values-from-a-dictionary-in-swift-3 which uses a combination of a set and a dictionary to insure that the dictionary only includes unique items.

// Actually we don't need a dictionary, just an array of UUID?

// See https://swiftrocks.com/weak-dictionary-values-in-swift for another solution.

// A mark may have up to three attachments to marks in the proximal and distal regions
// and in its own region, i.e. reentry spawning a mark.
struct MarkGroup: Codable {
    var proximal: MarkSet
    var middle: MarkSet
    var distal: MarkSet

    var allMarks: MarkSet {
        get {
            proximal.union(middle.union(distal))
        }
    }

    init(proximal: MarkSet = MarkSet(), middle: MarkSet = MarkSet(), distal: MarkSet = MarkSet()) {
        self.proximal = proximal
        self.middle = middle
        self.distal = distal
    }

    mutating func remove(mark: Mark) {
        proximal.remove(mark)
        middle.remove(mark)
        distal.remove(mark)
    }

    var count: Int { allMarks.count }

    func highlight(highlight: Mark.Highlight) {
        for mark in allMarks {
            mark.highlight = highlight
        }
    }
}

struct MarkIdGroup: Codable {
    var proximal: MarkIdSet
    var middle: MarkIdSet
    var distal: MarkIdSet

    var allMarkIds: MarkIdSet {
        proximal.union(middle.union(distal))
    }
    var count: Int {
        allMarkIds.count
    }

    init(proximal: MarkIdSet = MarkIdSet(),
         middle: MarkIdSet = MarkIdSet(),
         distal: MarkIdSet = MarkIdSet()) {
        self.proximal = proximal
        self.middle = middle
        self.distal = distal
    }

    mutating func remove(id: UUID) {
        proximal.remove(id)
        middle.remove(id)
        distal.remove(id)
    }
    
}

// The mark is a fundamental component of a ladder diagram.
class Mark: Codable {
    let id: UUID // each mark has a unique id to allow sets of marks

    var segment: Segment // where a mark is, using regional coordinates
//    { didSet {
//        print("test \(id) \(segment)")
//    }}

    var attached: Bool = false // cursor attached and shown
    var selected: Bool = false // mark is selected for some action
    var highlight: Highlight = .none
    var anchor: Anchor = .middle // Anchor point for movement and to attach a cursor
    var lineStyle: LineStyle = .solid
    var block: Block = .none
    var impulseOrigin: ImpulseOrigin = .none
    var text: String = ""  // text is usually a calibrated interval
    var showText: Bool = true
    // Ids of other marks that this mark is grouped with.
    var groupedMarkIds: MarkIdGroup = MarkIdGroup()
    var regionIndex: Int = -1 // keep track of which region mark is in a ladder, negative value should not occur, except on init.

    // Calculated properties
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

    init(segment: Segment) {
        self.segment = segment
        self.id = UUID()
        groupedMarkIds = MarkIdGroup()
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
        os_log("Mark deinitied %s", log: OSLog.debugging, type: .debug, debugDescription)
    }

    /// Return midpoint of mark as CGPoint
    func midpoint() -> CGPoint {
        let segment = self.segment.normalized()
        let x = (segment.distal.x - segment.proximal.x) / 2.0 + segment.proximal.x
        let y = (segment.distal.y - segment.proximal.y) / 2.0 + segment.proximal.y
        return CGPoint(x: x, y: y)
    }

    func midpointX() -> CGFloat {
        return (segment.distal.x - segment.proximal.x) / 2.0 + segment.proximal.x
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
            anchorPosition = segment.distal.clampY()
        case .middle:
            anchorPosition = midpoint()
        case .proximal:
            anchorPosition = segment.proximal.clampY()
        case .none:
            anchorPosition = segment.proximal.clampY()
        }
        return anchorPosition
    }

    // Note point must be in absolute coordinates, with y between 0 and 1 relative to region height.
    func distance(point: CGPoint) -> CGFloat {
        var numerator = (segment.distal.y - segment.proximal.y) * point.x - (segment.distal.x - segment.proximal.x) * point.y + segment.distal.x * segment.proximal.y - segment.distal.y * segment.proximal.x
        numerator = abs(numerator)
        var denominator = pow((segment.distal.y - segment.proximal.y), 2) + pow((segment.distal.x - segment.proximal.x), 2)
        denominator = sqrt(denominator)
        return numerator / denominator
    }
}
// MARK: - extensions

extension Mark: CustomDebugStringConvertible {
    var debugDescription: String {
        """
        \(id.debugDescription)
        \(segment)
        attached = \(attached)

        """
    }
}

extension Mark: Comparable {
    static func < (lhs: Mark, rhs: Mark) -> Bool {
        return lhs.segment.proximal.x < rhs.segment.proximal.x && lhs.segment.distal.x < rhs.segment.distal.x
    }

    static func == (lhs: Mark, rhs: Mark) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Mark: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// enums for Mark
extension Mark {
    /// Draw a solid or dashed line when drawing a mark.
    enum LineStyle: Int, Codable, CustomStringConvertible, CaseIterable, Identifiable {
        var id: LineStyle { self }

        var description: String {
            switch self {
            case .solid:
                return "Solid"
            case .dashed:
                return "Dashed"
            case .dotted:
                return "Dotted"
            }
        }

        case solid
        case dashed
        case dotted
    }

    // Highlight is used to show state of a mark visibly.
    enum Highlight: Int, Codable {
        case attached // cursor attached
        case grouped // mark attached to cursor and
        case selected
        case linked
        case none
    }

    // Site of block
    enum Block: Int, Codable {
        case proximal
        case distal
        case none
    }

    // Site of impulse origin
    enum ImpulseOrigin: Int, Codable {
        case proximal
        case distal
        case none
    }

}
