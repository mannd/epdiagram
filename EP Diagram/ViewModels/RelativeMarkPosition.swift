//
//  RelativeMarkPosition.swift
//  EP Diagram
//
//  Created by David Mann on 2/23/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

// Note: this is probably going to be totally unused code and should be deleted (the entire file) if it so proves to be.

// FIXME: experimental.
struct RelativeMarkPosition {
    var position: MarkPosition
    var proximal: CGPoint {
        get {
            position.proximal
        }
    }
    var distal: CGPoint {
        get {
            position.distal
        }
    }
    var offset: CGFloat
    var scale: CGFloat
    var rect: CGRect
    var absoluteMarkPosition: MarkPosition {
        get {
            return Common.translateToAbsoluteMarkPosition(markPosition: position, inRect: rect, offsetX: offset, scale: scale)
        }
        set(newPosition) {
            position = Common.translateToScreenMarkPosition(markPosition: newPosition, inRect: rect, offsetX: offset, scale: scale)
        }
    }

    init(relativePosition: MarkPosition, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) {
        position = relativePosition
        self.rect = rect
        self.offset = offset
        self.scale = scale
    }

    // Essentially a zeroed out RelativeMarkPosition.
    init() {
        position = MarkPosition(proximal: CGPoint.zero, distal: CGPoint.zero)
        rect = CGRect.zero
        offset = 0
        scale = 1.0
    }

    func getAbsoluteMarkPosition(inRect rect: CGRect) -> MarkPosition {
        return Common.translateToAbsoluteMarkPosition(markPosition: position, inRect: rect, offsetX: offset, scale: scale)
    }
}

// FIXME: Experimental
extension Mark {
    //    func setRelativeMarkPosition(relativeMarkPosition: RelativeMarkPosition) {
    //        position = relativeMarkPosition.absoluteMarkPosition
    //    }

    func setPosition(relativePosition: MarkPosition, in rect:CGRect, offset: CGFloat, scale: CGFloat) {
        position.proximal = Common.translateToRegionPosition(position: relativePosition.proximal, inRect: rect, offsetX: offset, scale: scale)
        position.distal = Common.translateToRegionPosition(position: relativePosition.distal, inRect: rect, offsetX: offset, scale: scale)
    }

    func getPosition(in rect:CGRect, offset: CGFloat, scale: CGFloat) -> MarkPosition {
        return MarkPosition(proximal: Common.translateToScreenPosition(position: position.proximal, inRect: rect, offsetX: offset, scale: scale), distal: Common.translateToScreenPosition(position: position.distal, inRect: rect, offsetX: offset, scale: scale))
    }

    convenience init(relativePosition: MarkPosition, in rect: CGRect, offset: CGFloat, scale: CGFloat) {
        self.init()
        setPosition(relativePosition: relativePosition, in: rect, offset: offset, scale: scale)
    }

}
