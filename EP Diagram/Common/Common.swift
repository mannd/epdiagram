//
//  Common.swift
//  EP Diagram
//
//  Created by David Mann on 7/24/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

/// Namespace for global static functions.
class Common {
    // Translates from LadderView X coordinate to Mark X coordinates.
    static func translateToAbsolutePositionX(positionX: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return (positionX + offset) / scale
    }

    // Translate from Mark X coordinate to LadderView X coordinate.
    static func translateToRelativePositionX(positionX: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return scale * positionX - offset
    }

    // translate mark points to and from host coordinate system
    static func translateToRelativePosition(position: CGPoint, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToRelativePositionX(positionX: position.x, offset: offset, scale: scale)
        let y = rect.origin.y + position.y * rect.height
        return CGPoint(x: x, y: y)
    }

    static func translateToAbsolutePosition(position: CGPoint, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToAbsolutePositionX(positionX: position.x, offset: offset, scale: scale)
        let y = (position.y - rect.origin.y) / rect.height
        return CGPoint(x: x, y: y)
    }

    // translate from absolute MarkPosition to relative MarkPosition
    static func translateToRelativeMarkPosition(markPosition: MarkPosition, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) -> MarkPosition {
        return MarkPosition(proximal: translateToRelativePosition(position: markPosition.proximal, inRect: rect, offsetX: offset, scale: scale), distal: translateToRelativePosition(position: markPosition.distal, inRect: rect, offsetX: offset, scale: scale))
    }

    // translate from relative MarkPosition to absolute MarkPosition
    static func translateToAbsoluteMarkPosition(markPosition: MarkPosition, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) -> MarkPosition {
        return MarkPosition(proximal: translateToAbsolutePosition(position: markPosition.proximal, inRect: rect, offsetX: offset, scale: scale), distal: translateToAbsolutePosition(position: markPosition.distal, inRect: rect, offsetX: offset, scale: scale))
    }

    /// Returns true if target is a Mac, false for iOS.
    static func isRunningOnMac() -> Bool {
        #if targetEnvironment(macCatalyst)
            return true
        #else
            return false
        #endif
    }
}

// MARK: - Global namespace functions

// A few macro-like functions in the global namespace.

/// Language localization "macro."
/// - Parameters:
///   - s: string to be translated
///   - comment: optional comment for translator
func L(_ s: String, comment: String = "") -> String {
    return NSLocalizedString(s, comment: comment)
}

#if DEBUG
/// Print logging info only while in debug mode.
/// - Parameter s: logging message to print
// Make false to suppress printing of messages, even in debug mode.
var printMessages = true
func P(_ s: String) {
    if printMessages {
        print(s)
    }
}
#endif
