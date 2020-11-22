//
//  Region.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

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



// MARK: - classes

// A Region is a row of a ladder corresponding to an anatomic substrate.
// A Region has a labelSection such as "A" or "AV" and
// a markSection.  Region boundaries are set by the calling ScaledView.
class Region: NSObject, NSCoding, Codable {


    private(set) var id = UUID()

    var name: String
    var longDescription: String
    var unitHeight: Int = 1
    var proximalBoundary: CGFloat = 0
    var distalBoundary: CGFloat = 0
    var activated: Bool = false
    var marks = [Mark]()
    var markable: Bool = true
    var height: CGFloat { distalBoundary - proximalBoundary }
    // TODO: Add style to region, which can be overrident, and set as a default in preferences
    // TODO: We can init lineStyle with the template lineStyle, but we need to be able to set it as well.
    var lineStyle: Mark.LineStyle = .solid

    private enum Keys: String, CustomStringConvertible {
        case name = "regionName"
        case longDescription = "regionLongDescription"
        case unitHeight = "regionUnitHeight"
        // etc.

        var description: String {
            return self.rawValue
        }
    }

    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: Keys.name.description)
        coder.encode(longDescription, forKey: Keys.longDescription.description)
        coder.encode(unitHeight, forKey: Keys.unitHeight.description)
    }

    required init?(coder: NSCoder) {
        guard let name = coder.decodeObject(forKey: Keys.name.description) as? String else { return nil }
        self.name = name
        longDescription = coder.decodeObject(forKey: Keys.longDescription.description) as? String ?? ""
        unitHeight = coder.decodeObject(forKey: Keys.unitHeight.description) as? Int ?? 1
    }

    // A region is copied from a template, after which the template is no longer referenced.
    init(template: RegionTemplate) {
        self.name = template.name
        self.longDescription = template.description
        self.unitHeight = template.unitHeight
        self.lineStyle = template.lineStyle
    }

    func appendMark(_ mark: Mark) {
        marks.append(mark)
    }

    func getRelativeYPosition(y: CGFloat) -> CGFloat? {
        guard y >= proximalBoundary && y <= distalBoundary else { return nil }
        return (y - proximalBoundary) / (distalBoundary - proximalBoundary)
    }

    // Two functions to use while moving marks to see is we are close to another mark
    // for purposes of highlighting them for connection.
    func getMarkProximalXPositions() -> [CGFloat] {
        var points = [CGFloat]()
        for mark in marks {
            points.append(mark.segment.proximal.x)
        }
        return points
    }

    func getMarkDistalXPositions() -> [CGFloat] {
        var points = [CGFloat]()
        for mark in marks {
            points.append(mark.segment.distal.x)
        }
        return points
    }
}

// MARK: - Extensions

//extension Region: CustomDebugStringConvertible {
//    var debugDescription: String { "Region ID " + id.debugDescription }
//}
//
//extension Region: Equatable {
//    static func == (lhs: Region, rhs: Region) -> Bool {
//        return lhs.id == rhs.id
//    }
//}
