//
//  ScaledView.swift
//  EP Diagram
//
//  Created by David Mann on 3/1/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit


/// An "abstract" class that manages transformations from view coordinates to ladder region coordinates
class ScaledView: UIView {
    var scale: CGFloat = 1 // scale determined by pinch to zoom == UIScrollView.zoomScale
    var offsetX: CGFloat = 0 // offsetX determined by scrolling == UIScrollView.contentOffset.x

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // Transformation functions.  These transform positions from Region coordinates (x = position in unzoomed, unscrolled region, y = 0..1.0 as a fraction of vertical height of region) to ScaledView (LadderView or CursorView) coordinates (the x,y position in the ScaledView) and vice versa.

    // PositionX functions

    /// Transform scaled view x coodinate to region x coordinate
    /// - Parameter scaledViewPositionX: scaled view x coordinate as `CGFloat `
    /// - Returns: region x coordinate as `CGFloat`
    func transformToRegionPositionX(scaledViewPositionX: CGFloat) -> CGFloat {
        return Transform.toRegionPositionX(scaledViewPositionX: scaledViewPositionX, offset: offsetX, scale: scale)
    }

    /// Transform region x coordinate to scaled view x coodinate
    /// - Parameter regionPositionX: region x coordinate as `CGFloat`
    /// - Returns: scaled view x coordinate as `CGFloat`
    func transformToScaledViewPositionX(regionPositionX: CGFloat) -> CGFloat {
        Transform.toScaledViewPositionX(regionPositionX: regionPositionX, offset:offsetX, scale: scale)
    }

    // Position functions

    /// Transform scaled view position to region position
    /// - Parameters:
    ///   - scaledViewPosition: scaled view position as `CGPoint`
    ///   - region: `Region` of scaled view position
    /// - Returns: region position as `CGPoint`
    func transformToRegionPosition(scaledViewPosition: CGPoint, region: Region) -> CGPoint {
        return Transform.toRegionPosition(scaledViewPosition: scaledViewPosition, region: region, offsetX: offsetX,scale: scale)
    }

    /// Transform region position to scaled view position
    /// - Parameters:
    ///   - regionPosition: region position as `CGPoint`
    ///   - region: `Region` of the region position
    /// - Returns: scaled view position as `CGPoint`
    func transformToScaledViewPosition(regionPosition: CGPoint, region: Region) -> CGPoint {
        Transform.toScaledViewPosition(regionPosition: regionPosition, region: region, offsetX: offsetX, scale: scale)
    }

    // Segment functions

    /// Transform region segment to scaled view segment
    /// - Parameters:
    ///   - regionSegment: region segment as `Segment`
    ///   - region: `Region` of the segment
    /// - Returns: `Segment` in scale view coordinates
    func transformToScaledViewSegment(regionSegment: Segment, region: Region) -> Segment {
        Transform.toScaledViewSegment(regionSegment: regionSegment, region: region, offsetX: offsetX, scale: scale)
    }

    /// Transform scaled view segment to region segment
    /// - Parameters:
    ///   - scaledViewSegment: scaled view segment as `Segment`
    ///   - region: `Region` of segment
    /// - Returns: `Segment` in region coordinates
    func transformToRegionSegment(scaledViewSegment: Segment, region: Region) -> Segment {
        Transform.toRegionSegment(scaledViewSegment: scaledViewSegment, region: region, offsetX: offsetX, scale: scale)
    }
}
