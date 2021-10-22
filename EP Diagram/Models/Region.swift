//
//  Region.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

// MARK: - classes

/// A Region is a row of a ladder corresponding to an anatomic substrate  and it contains marks.
/// A Region has a label section such as "A" or "AV" and
/// a mark section.  Region boundaries are set by the calling `LadderView`..
final class Region: Codable {
    private(set) var id = UUID()

    var name: String
    var longDescription: String
    var unitHeight: Int = 1
    var proximalBoundaryY: CGFloat = 0
    var distalBoundaryY: CGFloat = 0
    var mode: Mode = .normal
    var marks = [Mark]()
    var height: CGFloat { distalBoundaryY - proximalBoundaryY }
    private var _style: Mark.Style = .inherited

    var style: Mark.Style = .inherited

    /// Create a region from a `RegionTemplate`.
    ///
    /// A region is copied from a template, after which the template is no longer referenced.
    /// Used to add regions on the fly.
    init(template: RegionTemplate) {
        self.name = template.name
        self.longDescription = template.description
        self.unitHeight = template.unitHeight
        self.style = template.style
    }

    /// Creates a template from a region.
    ///
    /// A region can be converted to a region template.  Used when adding regions on the fly.
    func regionTemplate() -> RegionTemplate {
        let template = RegionTemplate(
            name: self.name,
            description: self.longDescription,
            unitHeight: self.unitHeight,
            style: self.style
        )
        return template
    }

    /// Add a mark to the region's array of marks.
    /// - Parameter mark: `Mark` to be added to this region.
    func appendMark(_ mark: Mark) {
        marks.append(mark)
    }


    /// Determines *region *y coordinate from a *scaled* y value.
    ///
    /// Region uses a hybrid coordinate system.  Marks always use region coordinates,
    /// but regions also know their boundaries as scaled coordinates.  However scaled y coordinates
    /// never change in the ladder with zoom or changes in content offset.  This function is at present
    /// only used for testing and is not in production code.
    /// - Parameter y: scaled y coordinate as `CGFloat`
    /// - Returns: region y coordinate as `CGFloat`.  Returns nil if y not within region boundaries.
    func relativeYPosition(y: CGFloat) -> CGFloat? {
        guard y >= proximalBoundaryY && y <= distalBoundaryY else { return nil }
        return (y - proximalBoundaryY) / (distalBoundaryY - proximalBoundaryY)
    }
}

// MARK: - extensions

extension Region: CustomDebugStringConvertible {
    var debugDescription: String { "Region ID " + id.debugDescription }
}

extension Region: Equatable {
    static func == (lhs: Region, rhs: Region) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Region {
    /// Region mode determines appearance and behavior of the region.
    enum Mode: Int, Codable {
        case active
        case selected
        case labelSelected
        case normal
    }
}

extension Region: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - enums

/// The two parts of a region.
enum RegionSection {
    case labelSection
    case markSection
}

/// LIke Gaul, all regions are divided vertically into three parts...
///
/// Used to determine what part of a region is tapped.
enum RegionDivision {
    case proximal
    case middle
    case distal
    case none
}


