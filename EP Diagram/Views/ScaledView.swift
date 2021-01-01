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

    // Translation functions.  These translate positions from Region coordinates (x = position in unzoomed, unscrolled region, y = 0..1.0 as a fraction of vertical height of region) to ScaledView (LadderView or CursorView) coordinates (the x,y position in the ScaledView) and vice versa.

    // PositionX functions.
    func translateToRegionPositionX(scaledViewPositionX: CGFloat) -> CGFloat {
        return Common.translateToRegionPositionX(scaledViewPositionX: scaledViewPositionX, offset: offsetX, scale: scale)
    }

    func translateToScaledViewPositionX(regionPositionX: CGFloat) -> CGFloat {
        Common.translateToScaledViewPositionX(regionPositionX: regionPositionX, offset:offsetX, scale: scale)
    }

    // Position functions
    func translateToRegionPosition(scaledViewPosition: CGPoint, region: Region) -> CGPoint {
        return Common.translateToRegionPosition(scaledViewPosition: scaledViewPosition, region: region, offsetX: offsetX,scale: scale)
    }

    func translateToScaledViewPosition(regionPosition: CGPoint, region: Region) -> CGPoint {
        Common.translateToScaledViewPosition(regionPosition: regionPosition, region: region, offsetX: offsetX, scale: scale)
    }

    // Segment functions.
    func translateToScaledViewSegment(regionSegment: Segment, region: Region) -> Segment {
        Common.translateToScaledViewSegment(regionSegment: regionSegment, region: region, offsetX: offsetX, scale: scale)
    }

    func translateToRegionSegment(scaledViewSegment: Segment, region: Region) -> Segment {
        Common.translateToRegionSegment(scaledViewSegment: scaledViewSegment, region: region, offsetX: offsetX, scale: scale)
    }
}
