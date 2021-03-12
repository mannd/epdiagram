//
//  Transform.swift
//  EP Diagram
//
//  Created by David Mann on 1/1/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit

enum Transform {
    // Positions:
    // There are 2 coordinate systems in use for positioning marks.
    // Region position: A point with x coordinate starting at the left margin of a region, and a y coordinate between 0 and 1.0, spanning the proximal to distal borders of the region.
    // Scaled position: A point in the coordinate system of the ladder view.
    // Note that region positions are NOT affected by scrolling (content offset) and scaling (zoom).
    // Functions below transform from one coordinate system to the other.
    // Note this is a transform (due to scaling) and not a translation mathematically.

    // PositionX transform
    static func toRegionPositionX(scaledViewPositionX: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return (scaledViewPositionX + offset) / scale
    }

    static func toScaledViewPositionX(regionPositionX: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return scale * regionPositionX - offset
    }

    // Position transform
    static func toRegionPosition(scaledViewPosition: CGPoint, region: Region, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = toRegionPositionX(scaledViewPositionX: scaledViewPosition.x, offset: offset, scale: scale)
        let y = (scaledViewPosition.y - region.proximalBoundaryY) / region.height
        return CGPoint(x: x, y: y)
    }

    static func toScaledViewPosition(regionPosition: CGPoint, region: Region, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = toScaledViewPositionX(regionPositionX: regionPosition.x, offset: offset, scale: scale)
        let y = region.proximalBoundaryY + regionPosition.y * region.height
        return CGPoint(x: x, y: y)
    }

    // Segment transform
    static func toScaledViewSegment(regionSegment: Segment, region: Region, offsetX offset: CGFloat, scale: CGFloat) -> Segment {
        return Segment(proximal: toScaledViewPosition(regionPosition: regionSegment.proximal, region: region, offsetX: offset, scale: scale), distal: toScaledViewPosition(regionPosition: regionSegment.distal, region: region, offsetX: offset, scale: scale))
    }

    static func toRegionSegment(scaledViewSegment: Segment, region: Region, offsetX offset: CGFloat, scale: CGFloat) -> Segment {
        return Segment(proximal: toRegionPosition(scaledViewPosition: scaledViewSegment.proximal, region: region, offsetX: offset, scale: scale), distal: toRegionPosition(scaledViewPosition: scaledViewSegment.distal, region: region, offsetX: offset, scale: scale))
    }
}
