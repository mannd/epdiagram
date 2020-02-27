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
    var position: Segment
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
    var absoluteMarkPosition: Segment {
        get {
            return Common.translateToRegionSegment(screenSegment: position, inRect: rect, offsetX: offset, scale: scale)
        }
        set(newPosition) {
            position = Common.translateToScreenSegment(regionSegment: newPosition, inRect: rect, offsetX: offset, scale: scale)
        }
    }

    init(relativePosition: Segment, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) {
        position = relativePosition
        self.rect = rect
        self.offset = offset
        self.scale = scale
    }

    // Essentially a zeroed out RelativeMarkPosition.
    init() {
        position = Segment(proximal: CGPoint.zero, distal: CGPoint.zero)
        rect = CGRect.zero
        offset = 0
        scale = 1.0
    }

    func getAbsoluteMarkPosition(inRect rect: CGRect) -> Segment {
        return Common.translateToRegionSegment(screenSegment: position, inRect: rect, offsetX: offset, scale: scale)
    }
}

// FIXME: Experimental
extension Mark {
    //    func setRelativeMarkPosition(relativeMarkPosition: RelativeMarkPosition) {
    //        position = relativeMarkPosition.absoluteMarkPosition
    //    }

    func setPosition(relativePosition: Segment, in rect:CGRect, offset: CGFloat, scale: CGFloat) {
        segment.proximal = Common.translateToRegionPosition(position: relativePosition.proximal, inRect: rect, offsetX: offset, scale: scale)
        segment.distal = Common.translateToRegionPosition(position: relativePosition.distal, inRect: rect, offsetX: offset, scale: scale)
    }

    func getPosition(in rect:CGRect, offset: CGFloat, scale: CGFloat) -> Segment {
        return Segment(proximal: Common.translateToScreenPosition(position: segment.proximal, inRect: rect, offsetX: offset, scale: scale), distal: Common.translateToScreenPosition(position: segment.distal, inRect: rect, offsetX: offset, scale: scale))
    }

    convenience init(relativePosition: Segment, in rect: CGRect, offset: CGFloat, scale: CGFloat) {
        self.init()
        setPosition(relativePosition: relativePosition, in: rect, offset: offset, scale: scale)
    }

}
