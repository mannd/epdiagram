//
//  LocationInLadder.swift
//  EP Diagram
//
//  Created by David Mann on 4/29/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

/// Struct that pinpoints a point in a ladder.  Note that these tapped areas overlap (labels and marks are in regions).
struct LocationInLadder {
    var region: Region?
    var mark: Mark?
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
}

