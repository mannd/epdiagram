//
//  Anchor.swift
//  EP Diagram
//
//  Created by David Mann on 10/23/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import Foundation

/// Used to anchor the cursor to a point of a mark's segment.
/// Anchors also determine how marks move.  When moving the proximal anchor,
/// the distal anchor stays fixed, and vice versa.  Moving the middle anchor moves
/// the whole mark as a unit.
enum Anchor: Int, Codable {
    case middle
    case proximal
    case distal
}
