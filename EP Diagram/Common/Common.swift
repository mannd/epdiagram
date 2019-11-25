//
//  Common.swift
//  EP Diagram
//
//  Created by David Mann on 7/24/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

extension UIView {
    // Translates from LadderView coordinates to Mark coordinates.
    func translateToAbsoluteLocation(location: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return Common.translateToAbsoluteLocation(location: location, offset: offset, scale: scale)
    }

    // Translate from Mark coordinates to LadderView coordinates.
    func translateToRelativeLocation(location: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return Common.translateToRelativeLocation(location: location, offset: offset, scale: scale)
    }
}

class Common {
    // Translates from LadderView coordinates to Mark coordinates.
    static func translateToAbsoluteLocation(location: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return (location + offset) / scale
    }

    // Translate from Mark coordinates to LadderView coordinates.
    static func translateToRelativeLocation(location: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return scale * location - offset
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

