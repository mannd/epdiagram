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
        return (location + offset) / scale
    }

    // Translate from Mark coordinates to LadderView coordinates.
    func translateToRelativeLocation(location: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return scale * location - offset
    }
}

