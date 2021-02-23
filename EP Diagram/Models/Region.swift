//
//  Region.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

// MARK: - classes

/// A Region is a row of a ladder corresponding to an anatomic substrate.
/// A Region has a labelSection such as "A" or "AV" and
/// a markSection.  Region boundaries are set by the calling ScaledView.
final class Region: Codable {
    private(set) var id = UUID()

    var name: String
    var longDescription: String
    var unitHeight: Int = 1
    var proximalBoundary: CGFloat = 0
    var distalBoundary: CGFloat = 0
    var mode: Mode = .normal
    var marks = [Mark]()
    var height: CGFloat { distalBoundary - proximalBoundary }
    private var _style: Mark.Style = .inherited

    var style: Mark.Style = .inherited

//    var style: Mark.Style {
//        get {
//            if _style == .inherited {
//                return Mark.Style(rawValue: Preferences.markStyle) ?? .solid
//            }
//            return _style
//        }
//        set(newValue) {
//            _style = newValue
//        }
//    }

    /// A region is copied from a template, after which the template is no longer referenced.
    /// Used to add regions on the fly.
    init(template: RegionTemplate) {
        self.name = template.name
        self.longDescription = template.description
        self.unitHeight = template.unitHeight
        self.style = template.style
    }

    /// Creates a template from a region.
    func regionTemplate() -> RegionTemplate {
        let template = RegionTemplate(
            name: self.name,
            description: self.longDescription,
            unitHeight: self.unitHeight,
            style: self.style
        )
        return template
    }

    func appendMark(_ mark: Mark) {
        marks.append(mark)
    }

    func relativeYPosition(y: CGFloat) -> CGFloat? {
        guard y >= proximalBoundary && y <= distalBoundary else { return nil }
        return (y - proximalBoundary) / (distalBoundary - proximalBoundary)
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

// The two parts of a region.
enum RegionSection {
    case labelSection
    case markSection
}

/// All regions are divided vertically into three parts...
enum RegionDivision {
    case proximal
    case middle
    case distal
    case none
}


