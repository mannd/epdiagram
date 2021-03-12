//
//  LocationInLadder.swift
//  EP Diagram
//
//  Created by David Mann on 4/29/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

// MARK: - structs

/// Struct that pinpoints a point in a ladder.  Note that these tapped areas overlap (labels and marks are in regions).
struct LocationInLadder {
    enum SpecificLocation {
        case ladder
        case label
        case region
        case zone
        case mark
        case error
    }

    var region: Region?
    var mark: Mark?
    var ladder: Ladder?
    var zone: Zone?
    var regionSection: RegionSection
    var regionDivision: RegionDivision
    var markAnchor: Anchor?
    var unscaledPosition: CGPoint
    var specificLocation: SpecificLocation {
        if mark != nil {
            return .mark
        }
        if zone != nil {
            return .zone
        }
        if regionSection == .labelSection {
            return .label
        }
        if region != nil {
            return .region
        }
        if region == nil {
            return .ladder
        }
        return .error
    }
}

// MARK: - extensions

extension LocationInLadder: CustomDebugStringConvertible {
    var debugDescription: String {
        let description = """
        LocationInLadder ------
        -----------------------
        region = \(region.debugDescription)
        mark = \(mark.debugDescription)
        ladder = \(ladder.debugDescription)
        zone = \(zone.debugDescription)

        regionSection = \(regionSection)
        regionDivision = \(regionDivision)

        markAnchor = \(markAnchor.debugDescription)
        unscaledPosition = \(unscaledPosition)
        specificLocation = \(specificLocation)
        """
        return description
    }
}

