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
import BetterCodable
import os.log

// MARK: - typealiases

typealias MarkSet = Set<Mark>
typealias MarkIdSet = Set<UUID>

// MARK: - classes

/// The mark is a fundamental component of a ladder diagram.
final class Mark: Codable {
    let id: UUID // each mark has a unique id to allow sets of marks

    var segment: Segment // where a mark is, using regional coordinates
    var mode: Mode = .normal
    var anchor: Anchor = .middle // Anchor point for movement and cursor attachment
    var style: Style = .solid
    var emphasis: Emphasis = .normal
    var blockSite: Endpoint = .none
    var blockSetting: Endpoint = .auto
    var impulseOriginSite: Endpoint = .none
    var impulseOriginSetting: Endpoint = .auto

    // Ids of other marks that this mark is linked with.
    var linkedMarkIDs: LinkedMarkIDs = LinkedMarkIDs()
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
        get { segment.length }
    }

    /// Position of earliest point on mark.
    var earliestPoint: CGPoint { return segment.earliestPoint }

    /// Position of latest point on mark.
    var latestPoint: CGPoint { segment.latestPoint }

    /// The earlier of the two endpoints, Endpoint.none if mark is vertical.
    var earlyEndpoint: Endpoint {
        if segment.proximal.x < segment.distal.x {
            return .proximal
        }
        if segment.proximal.x > segment.distal.x {
            return .distal
        }
        return .none  // equal within floating point precision, i.e. vertical mark
    }

    /// The later of the two endpoints, Enpoint.none if mark is vertical.
    var lateEndpoint: Endpoint {
        if segment.proximal.x < segment.distal.x {
            return .distal
        }
        if segment.proximal.x > segment.distal.x {
            return .proximal
        }
        return .none
    }

    // MARK: - version 1.1.0 additions to Mark
    @DefaultCodable<MarkLabel> var leftLabel: String?  = nil
    @DefaultCodable<MarkLabel> var proximalLabel: String?  = nil
    @DefaultCodable<MarkLabel> var distalLabel: String?  = nil

    /// A String label for Mark, located at a LabelPosition
    struct MarkLabel: DefaultCodableStrategy {
        typealias DefaultValue = String?
        static var defaultValue: DefaultValue { return nil }
    }

    /// Where a MarkLabel is located in relation to a Mark
    enum LabelPosition: Int, Codable, CaseIterable {
        case left
        case proximal
        case distal
    }

    // MARK: - version 1.2.0 additions to Mark

    @DefaultEmptyArray var periods: [Period] = []
//    @DefaultFalse var isHidden: Bool = true

    // MARK: - Init

    /// Create a mark from a segment.
    init(segment: Segment) {
        self.segment = segment
        self.id = UUID()
        linkedMarkIDs = LinkedMarkIDs()
        anchor = .middle
        periods.append(Period(name: "test", duration: 500))
        periods.append(Period(name: "test2", duration: 150))
    }

    /// Create a mark with a zero length segment.  Mostly used for testing.
    convenience init() {
        self.init(segment: Segment(proximal: CGPoint.zero, distal: CGPoint.zero))
    }

    /// Create a mark that is vertical and spans a region.
    convenience init(positionX: CGFloat) {
        let segment = Segment(proximal: CGPoint(x: positionX, y: 0), distal: CGPoint(x: positionX, y:1.0))
        self.init(segment: segment)
    }

    /// Available for debugging.
    deinit {
        //os_log("Mark deinitied %s", log: OSLog.debugging, type: .debug, debugDescription)
    }

    /// Returns midpoint of mark segment  as CGPoint`.
    /// - Returns:  midpoint of the mark segment
    func midpoint() -> CGPoint {
        let segment = self.segment.normalized()
        let x = (segment.distal.x - segment.proximal.x) / 2.0 + segment.proximal.x
        let y = (segment.distal.y - segment.proximal.y) / 2.0 + segment.proximal.y
        return CGPoint(x: x, y: y)
    }

    /// Returns midpoint x coordinate.
    /// - Returns:  midpoint x coordinate as `CGFloat`
    func midpointX() -> CGFloat {
        return (segment.distal.x - segment.proximal.x) / 2.0 + segment.proximal.x
    }

    /// Swaps the proximal and distal ends of the mark segment.
    func swapEnds() {
        (segment.proximal, segment.distal) = (segment.distal, segment.proximal)
    }


    /// Swaps proximal and distal anchor positions.
    func swapAnchors() {
        switch anchor {
        case .proximal:
            anchor = .distal
        case .distal:
            anchor = .proximal
        default:
            break
        }
    }

    /// Returns position of anchor in region coordinates.
    /// - Returns:  Returns anchor position as CGPoint`
    func getAnchorPosition() -> CGPoint {
        let anchorPosition: CGPoint
        switch anchor {
        case .distal:
            anchorPosition = segment.distal.clampY()
        case .middle:
            anchorPosition = midpoint()
        case .proximal:
            anchorPosition = segment.proximal.clampY()
        }
        return anchorPosition
    }

    /// Returns shortest distance of a point in region coordinates to the mark.
    ///
    /// - Parameter point: a `CGPoint` in region coordinates
    /// - Returns: closest distance between the point and the mark as `CGFloat  `
    func distance(point: CGPoint) -> CGFloat {
        var numerator = (segment.distal.y - segment.proximal.y) * point.x - (segment.distal.x - segment.proximal.x) * point.y + segment.distal.x * segment.proximal.y - segment.distal.y * segment.proximal.x
        numerator = abs(numerator)
        var denominator = pow((segment.distal.y - segment.proximal.y), 2) + pow((segment.distal.x - segment.proximal.x), 2)
        denominator = sqrt(denominator)
        return numerator / denominator
    }

    /// Move mark to region position, depending on movement type and anchor position
    ///
    /// Used in testing but not currently used in app.
    ///
    /// - Parameters:
    ///   - movement: type of movement (horizontal or omnidirectional)
    ///   - position: point to move to, in region coordinates
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
            }
        }
    }


    /// Apply an angle to a mark.
    ///
    /// Only used for testing at present,  not in production code.
    /// - Parameter angle: angle in degrees as `CGFloat`
    func applyAngle(_ angle: CGFloat) {
        let y0 = segment.proximal.y
        let y1 = segment.distal.y
        let height = y1 - y0
        let delta = Geometry.rightTriangleBase(withAngle: angle, height: height)
        segment.distal.x += delta
    }

    // MARK: - static functions

    /// Returns a segment that represents movement of a mark.
    ///
    /// - Parameters:
    ///   - mark: the `Mark` to be moved
    ///   - movement: a `Movement` type (horizontal or omindirectional
    ///   - position: `CGPoint` in region coordinates to move to
    /// - Returns: a `Segment` reporesenting the position of the mark after movement.
    ///            Setting the mark segment to this segment will move the mark.
    static func segmentAfterMovement(mark: Mark, movement: Movement, to position: CGPoint) -> Segment {
        var segment = mark.segment
        let anchor = mark.anchor
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
            }
        }
        return segment
    }

}

// MARK: structs

/// A mark may have up to three attachments to marks in the proximal and distal regions
/// and in its own region, i.e. reentry spawning a mark.
struct LinkedMarks: Codable {
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
        allMarks.forEach { $0.mode = mode }
    }
}

/// Linked marks are actually tracked by marks as mark ids, to prevent recursion.
struct LinkedMarkIDs: Codable {
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

    mutating func removeAll() {
        proximal.removeAll()
        middle.removeAll()
        distal.removeAll()
    }
}

//struct MarkLabel: Codable {
//    var label: String?
//    var position: LabelPosition = .left
//
//    enum LabelPosition: Int, Codable {
//        case proximal
//        case distal
//        case left
//        case right
//    }
//}

// MARK: - extensions

extension Mark: CustomDebugStringConvertible {
    var debugDescription: String {
        let description = """

        ***Mark***
        \(id.debugDescription)
        \(segment)
        mark mode = \(mode)
        linked mark IDs = \(linkedMarkIDs)
        *********

        """
        return description
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

// MARK: - Mark enums

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
                return L("Default")
            }

        }
    }

    /// Analagous to bold text, make a mark thicker for emphasis.
    enum Emphasis: Int, Codable, CustomStringConvertible, CaseIterable {
        case normal
        case bold

        var description: String {
            switch self {
            case .normal:
                return L("Normal")
            case .bold:
                return L("Bold")
            }
        }

    }

    /// Mutually exclusive modes that determine behavior and appears of marks.
    enum Mode: Int, Codable {
        case attached
        case linked
        case selected
        case connected
        case normal
    }

    /// Show which end of a mark is affected by an action.
    enum Endpoint: String, Codable, CaseIterable, Identifiable {
        case proximal
        case distal
        case random
        case none
        case auto

        var id: String { return rawValue }
    }
}

// MARK: - enums

/// Freedom of movement for a mark.  It can move either horizontally or in any direction.
enum Movement {
    case horizontal
    case omnidirectional
}
