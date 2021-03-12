//
//  ScaledView.swift
//  EP Diagram
//
//  Created by David Mann on 3/1/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

class ScaledView: UIView {
    var scale: CGFloat = 1 // scale determined by pinch to zoom.
    var offsetX: CGFloat = 0 // offsetX determined by scrolling.

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // Transformation functions.  These transform positions from Region coordinates (x = position in unzoomed, unscrolled region, y = 0..1.0 as a fraction of vertical height of region) to ScaledView (LadderView or CursorView) coordinates (the x,y position in the ScaledView) and vice versa.

    // PositionX functions.
    func transformToRegionPositionX(scaledViewPositionX: CGFloat) -> CGFloat {
        return Transform.toRegionPositionX(scaledViewPositionX: scaledViewPositionX, offset: offsetX, scale: scale)
    }

    func transformToScaledViewPositionX(regionPositionX: CGFloat) -> CGFloat {
        Transform.toScaledViewPositionX(regionPositionX: regionPositionX, offset:offsetX, scale: scale)
    }

    // Position functions
    func transformToRegionPosition(scaledViewPosition: CGPoint, region: Region) -> CGPoint {
        return Transform.toRegionPosition(scaledViewPosition: scaledViewPosition, region: region, offsetX: offsetX,scale: scale)
    }

    func transformToScaledViewPosition(regionPosition: CGPoint, region: Region) -> CGPoint {
        Transform.toScaledViewPosition(regionPosition: regionPosition, region: region, offsetX: offsetX, scale: scale)
    }

    // Segment functions.
    func transformToScaledViewSegment(regionSegment: Segment, region: Region) -> Segment {
        Transform.toScaledViewSegment(regionSegment: regionSegment, region: region, offsetX: offsetX, scale: scale)
    }

    func transformToRegionSegment(scaledViewSegment: Segment, region: Region) -> Segment {
        Transform.toRegionSegment(scaledViewSegment: scaledViewSegment, region: region, offsetX: offsetX, scale: scale)
    }
}
