//
//  ScaledViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 2/23/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

class ScaledViewModel: NSObject {
    var scale: CGFloat = 1
    var offset: CGFloat = 0

    func translateToRegionPositionX(screenPositionX: CGFloat) -> CGFloat {
        return Common.translateToRegionPositionX(ladderViewPositionX: screenPositionX, offset: offset, scale: scale)
    }
    
    func translateToScreenPosition(regionPosition: CGPoint, regionProximalBoundary: CGFloat, regionHeight: CGFloat) -> CGPoint {
        Common.translateToLadderViewPosition(regionPosition: regionPosition, regionProximalBoundary: regionProximalBoundary, regionHeight: regionHeight, offsetX: offset, scale: scale)
    }

    func translateToScreenPosition(regionPosition: CGPoint, region: Region) -> CGPoint {
        Common.translateToLadderViewPosition(regionPosition: regionPosition, regionProximalBoundary: region.proximalBoundary, regionHeight: region.height, offsetX: offset, scale: scale)
    }

    func translateToScreenPositionX(regionPositionX: CGFloat) -> CGFloat {
        Common.translateToLadderViewPositionX(regionPositionX: regionPositionX, offset:offset, scale: scale)
    }

    func translateToRegionPosition(screenPosition: CGPoint, regionProximalBoundary: CGFloat, regionHeight: CGFloat) -> CGPoint {
        return Common.translateToRegionPosition(ladderViewPosition: screenPosition, regionProximalBoundary: regionProximalBoundary, regionHeight: regionHeight, offsetX: offset,scale: scale)
    }

    func translateToRegionPosition(screenPosition: CGPoint, region: Region) -> CGPoint {
        return Common.translateToRegionPosition(ladderViewPosition: screenPosition, regionProximalBoundary: region.proximalBoundary, regionHeight: region.height, offsetX: offset,scale: scale)
    }
}
