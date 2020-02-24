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

    func translateToAbsolutePositionX(positionX: CGFloat) -> CGFloat {
        return Common.translateToAbsolutePositionX(positionX: positionX, offset: offset, scale: scale)
    }
    
    func translateToRelativePosition(position: CGPoint, regionProximalBoundary: CGFloat, regionHeight: CGFloat) -> CGPoint {
        Common.translateToRelativePosition(position: position, regionProximalBoundary: regionProximalBoundary, regionHeight: regionHeight, offsetX: offset, scale: scale)
    }

    func translateToRelativePositionX(positionX: CGFloat) -> CGFloat {
        Common.translateToRelativePositionX(positionX: positionX, offset:offset, scale: scale)
    }
}
