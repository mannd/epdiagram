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
    var regionWasTapped: Bool {
        region != nil
    }
    var labelWasTapped: Bool {
        regionSection == .labelSection
    }
    var markWasTapped: Bool {
        mark != nil
    }
    var ladderWasTapped: Bool {
        // If tapped outside of all regions, assume whole ladder tapped.
        region == nil
    }
    var zoneWasTapped: Bool = false
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
        regionWasTapped = \(regionWasTapped)
        labelWasTapped = \(labelWasTapped)
        markWasTapped = \(markWasTapped)
        ladderWasTapped = \(ladderWasTapped)
        zoneWasTapped = \(zoneWasTapped)
        
        """
        return description
    }
}

