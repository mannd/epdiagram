//
//  Mark.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

// See this attempt at a ladder diagram program, the only one I can find: https://epfellow.wordpress.com/2010/11/04/electrocardiogram-ecgekg-ladder-diagrams/

// We import UIKit here and elsewhere to use CGFloat consistently and avoid conversions
// of Double to CGFloat.
import UIKit
import os.log

// MARK: - typealiases

typealias MarkSet = Set<Mark>
typealias MarkIdSet = Set<UUID>

// MARK: - classes, structs

/// The mark is a fundamental component of a ladder diagram.
class Mark: Codable {
    let id: UUID // each mark has a unique id to allow sets of marks

    var segment: Segment // where a mark is, using regional coordinates

    var mode: Mode = .normal
    var anchor: Anchor = .middle // Anchor point for movement and to attach a cursor
    var style: Style = .solid
    var block: Block = .none
    var impulseOrigin: ImpulseOrigin = .none
    var measurementText: String = ""
    var showMeasurementText: Bool = true

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
        (segment.proximal, segment.distal) = (segment.distal, segment.proximal)
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

    func move(movement: Movement, to position: CGPoint) {
        if movement == .horizontal {
            switch anchor {
            case .proximal:
                segment.proximal.x = position.x
            case .middle:
                // Determine halfway point between proximal and distal.
                let differenceX = (segment.proximal.x - segment.distal.x) / 2
                segment.proximal.x = position.x + differenceX
                segment.distal.x = position.x - differenceX
            case .distal:
                segment.distal.x = position.x
            case .none:
                break
            }
        }
        else if movement == .omnidirectional {
            switch anchor {
            case .proximal:
                segment.proximal = position
            case .middle:
                // Determine halfway point between proximal and distal.
                let differenceX = (segment.proximal.x - segment.distal.x) / 2
                let differenceY = (segment.proximal.y - segment.distal.y) / 2
                segment.proximal.x = position.x + differenceX
                segment.distal.x = position.x - differenceX
                segment.proximal.y = position.y + differenceY
                segment.distal.y = position.y - differenceY
            case .distal:
                segment.distal = position
            case .none:
                break
            }
        }
    }

    // Must normalize x and y??
    func applyAngle(_ angle: CGFloat) {
        let y0 = segment.proximal.y
        let y1 = segment.distal.y
        let height = y1 - y0
        let delta = Geometry.rightTriangleBase(withAngle: angle, height: height)
        segment.distal.x += delta
    }
}

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

    func setMode(_ mode: Mark.Mode) {
        allMarks.forEach { mark in mark.mode = mode }
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

// MARK: - extensions

extension Mark: CustomDebugStringConvertible {
    var debugDescription: String {
        """
        \(id.debugDescription)
        \(segment)
        mode = \(mode)
        """
    }
}

extension Mark: Comparable, Hashable {
    static func < (lhs: Mark, rhs: Mark) -> Bool {
        return lhs.segment.proximal.x < rhs.segment.proximal.x && lhs.segment.distal.x < rhs.segment.distal.x
    }

    static func == (lhs: Mark, rhs: Mark) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// enums for Mark
extension Mark {
    /// Draw a solid or dashed line when drawing a mark.
    enum Style: Int, Codable, CustomStringConvertible, CaseIterable, Identifiable {
        case solid
        case dashed
        case dotted
        case inherited

        var id: Style { self }
        var description: String {
            switch self {
            case .solid:
                return L("Solid")
            case .dashed:
                return L("Dashed")
            case .dotted:
                return L("Dotted")
            case .inherited:
                return L("Inherited")
            }

        }
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

    // Mutually exclusive modes that determine behavior and appears of marks.
    enum Mode: Int, Codable {
        case attached
        case grouped
        case selected
        case linked
        case normal
    }
}

// MARK: - enums

enum Movement {
    case horizontal
    case omnidirectional
}
