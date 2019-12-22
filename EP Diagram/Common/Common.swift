//
//  Common.swift
//  EP Diagram
//
//  Created by David Mann on 7/24/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class Common {
    // Translates from LadderView coordinates to Mark coordinates.
    static func translateToAbsoluteLocation(location: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return (location + offset) / scale
    }

    // Translate from Mark coordinates to LadderView coordinates.
    static func translateToRelativeLocation(location: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return scale * location - offset
    }

    // translate mark points to and from host coordinate system
    static func translateToRelativePosition(location: CGPoint, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToRelativeLocation(location: location.x, offset: offset, scale: scale)
        let y = rect.origin.y + location.y * rect.height
        return CGPoint(x: x, y: y)
    }

    static func translateToAbsolutePosition(location: CGPoint, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToAbsoluteLocation(location: location.x, offset: offset, scale: scale)
        let y = (location.y - rect.origin.y) / rect.height
        return CGPoint(x: x, y: y)
    }
}

// Make false to suppress printing of messages.
var printMessages = true

#if DEBUG
func PRINT(_ s: String) {
    if printMessages {
        print(s)
    }
}
#endif

