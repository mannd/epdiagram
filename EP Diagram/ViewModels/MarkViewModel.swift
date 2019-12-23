//
//  MarkViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 12/14/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

// Handles interface between View coordinates and Marks
class MarkViewModel: NSObject {
    var mark: Mark = Mark()
    var scale: CGFloat = 1.0
    var offset: CGFloat = 0
    var rect: CGRect = CGRect()

    // Or is a func better, always sending in scale, offset and rect?
    var position: MarkPosition {
        set(newPosition) {
            mark.position.proximal = Common.translateToAbsolutePosition(position: newPosition.proximal, inRect: rect, offsetX: offset, scale: scale)
            mark.position.distal = Common.translateToAbsolutePosition(position: newPosition.distal, inRect: rect, offsetX: offset, scale: scale)
        }
        get {
            return MarkPosition(proximal: Common.translateToRelativePosition(position: mark.position.proximal, inRect: rect, offsetX: offset, scale: scale), distal: Common.translateToRelativePosition(position: mark.position.distal, inRect: rect, offsetX: offset, scale: scale))
        }
    }

}



