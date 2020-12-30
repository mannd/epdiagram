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
    var region: Region?
    var mark: Mark?
    var ladder: Ladder?
    var zone: Zone?
    var regionSection: RegionSection
    var regionDivision: RegionDivision
    var markAnchor: Anchor
    var unscaledPosition: CGPoint
    var isRegion: Bool {
        region != nil
    }
    var isRegionNotLabel: Bool {
        isRegion && !isLabel
    }
    var isLabel: Bool {
        regionSection == .labelSection
    }
    var isMark: Bool {
        mark != nil
    }
    var isLadder: Bool {
        // If tapped outside of all regions, assume whole ladder tapped.
        region == nil
    }
    var isZone: Bool {
        zone != nil
    }
}

// MARK: - extensions

extension LocationInLadder: CustomDebugStringConvertible {
    var debugDescription: String {
        let description = """
        region = \(region.debugDescription)
        mark = \(mark.debugDescription)
        ladder = \(ladder.debugDescription)
        zone = \(zone.debugDescription)

        regionSection = \(regionSection)
        regionDivision = \(regionDivision)

        markAnchor = \(markAnchor)
        unscaledPosition = \(unscaledPosition)
        isRegion = \(isRegion)
        isLabel = \(isLabel)
        isMark = \(isMark)
        isLadder = \(isLadder)
        isZone = \(isZone)
        """
        return description
    }
}

