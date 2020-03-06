//
//  ScaledView.swift
//  EP Diagram
//
//  Created by David Mann on 3/1/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

class ScaledView: UIView {
    // scale determined by pinch to zoom.
    var scale: CGFloat = 1
    // offsetX determined by scrolling.
    var offsetX: CGFloat = 0
    // DEPRECATED
    // offsetY is the distance from the top of the cursorView to the top of the ladderView, set by LadderView.
    var offsetY: CGFloat = 0

    // Translation functions.  These translate positions from Region coordinates (x = position in unzoomed, unscrolled region, y = 0..1.0 as a fraction of vertical height of region) to LadderView coordinates (the x,y position in the LadderView) and vice versa.

    // PositionX functions.
    func translateToRegionPositionX(ladderViewPositionX: CGFloat) -> CGFloat {
        return Common.translateToRegionPositionX(ladderViewPositionX: ladderViewPositionX, offset: offsetX, scale: scale)
    }

    func translateToLadderViewPositionX(regionPositionX: CGFloat) -> CGFloat {
        Common.translateToLadderViewPositionX(regionPositionX: regionPositionX, offset:offsetX, scale: scale)
    }

    // Position functions using region proximal boundary and height.
    func translateToRegionPosition(ladderViewPosition: CGPoint, regionProximalBoundary: CGFloat, regionHeight: CGFloat) -> CGPoint {
        return Common.translateToRegionPosition(ladderViewPosition: ladderViewPosition, regionProximalBoundary: regionProximalBoundary, regionHeight: regionHeight, offsetX: offsetX,scale: scale)
    }

    func translateToLadderViewPosition(regionPosition: CGPoint, regionProximalBoundary: CGFloat, regionHeight: CGFloat) -> CGPoint {
        Common.translateToLadderViewPosition(regionPosition: regionPosition, regionProximalBoundary: regionProximalBoundary, regionHeight: regionHeight, offsetX: offsetX, scale: scale)
    }

    // Position functions using region.
    func translateToRegionPosition(ladderViewPosition: CGPoint, region: Region) -> CGPoint {
        return Common.translateToRegionPosition(ladderViewPosition: ladderViewPosition, regionProximalBoundary: region.proximalBoundary, regionHeight: region.height, offsetX: offsetX,scale: scale)
    }

    func translateToLadderViewPosition(regionPosition: CGPoint, region: Region) -> CGPoint {
        Common.translateToLadderViewPosition(regionPosition: regionPosition, regionProximalBoundary: region.proximalBoundary, regionHeight: region.height, offsetX: offsetX, scale: scale)
    }

    // Segment functions.
    func translateToLadderViewSegment(regionSegment: Segment, region: Region) -> Segment {
        Common.translateToLadderViewSegment(regionSegment: regionSegment, regionProximalBoundary: region.proximalBoundary, regionHeight: region.height, offsetX: offsetX, scale: scale)
    }

    // Screen functions.
    func translateToScreenPosition(regionPosition: CGPoint, regionProximalBoundary: CGFloat, regionHeight: CGFloat) -> CGPoint {
        Common.translateToScreenPosition(regionPosition: regionPosition, regionProximalBoundary: regionProximalBoundary, regionHeight: regionHeight, offsetX: offsetX, offsetY: offsetY, scale: scale)
    }

}
