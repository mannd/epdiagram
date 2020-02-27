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
    static func translateToRegionPositionX(screenPositionX: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return (screenPositionX + offset) / scale
    }

    static func translateToScreenPositionX(regionPositionX: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return scale * regionPositionX - offset
    }


    static func translateToScreenPosition(regionPosition: CGPoint, regionProximalBoundary proxBoundary: CGFloat, regionHeight height: CGFloat, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToScreenPositionX(regionPositionX: regionPosition.x, offset: offset, scale: scale)
        let y = proxBoundary + regionPosition.y * height
        return CGPoint(x: x, y: y)
    }

    static func translateToScreenMarkPosition(regionMarkPosition: MarkPosition, regionProximalBoundary proxBoundary: CGFloat, regionHeight height: CGFloat, offsetX offset: CGFloat, scale: CGFloat) -> MarkPosition {
        return MarkPosition(proximal: translateToScreenPosition(regionPosition: regionMarkPosition.proximal, regionProximalBoundary: proxBoundary, regionHeight: height, offsetX: offset, scale: scale), distal: translateToScreenPosition(regionPosition: regionMarkPosition.distal, regionProximalBoundary: proxBoundary, regionHeight: height, offsetX: offset, scale: scale))
    }

    static func translateToRegionPosition(screenPosition: CGPoint, regionProximalBoundary proxBoundary: CGFloat, regionHeight height: CGFloat, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToRegionPositionX(screenPositionX: screenPosition.x, offset: offset, scale: scale)
        let y = (screenPosition.y - proxBoundary) / height
        return CGPoint(x: x, y: y)
    }

    // Rect based translation function -- deprecated
    static func translateToScreenPosition(position: CGPoint, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToScreenPositionX(regionPositionX: position.x, offset: offset, scale: scale)
        let y = rect.origin.y + position.y * rect.height
        return CGPoint(x: x, y: y)
    }

    static func translateToRegionPosition(position: CGPoint, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToRegionPositionX(screenPositionX: position.x, offset: offset, scale: scale)
        let y = (position.y - rect.origin.y) / rect.height
        return CGPoint(x: x, y: y)
    }

    static func translateToScreenMarkPosition(markPosition: MarkPosition, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) -> MarkPosition {
        return MarkPosition(proximal: translateToScreenPosition(position: markPosition.proximal, inRect: rect, offsetX: offset, scale: scale), distal: translateToScreenPosition(position: markPosition.distal, inRect: rect, offsetX: offset, scale: scale))
    }

    static func translateToAbsoluteMarkPosition(markPosition: MarkPosition, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) -> MarkPosition {
        return MarkPosition(proximal: translateToRegionPosition(position: markPosition.proximal, inRect: rect, offsetX: offset, scale: scale), distal: translateToRegionPosition(position: markPosition.distal, inRect: rect, offsetX: offset, scale: scale))
    }
    static func getMidpoint(markPosition pos: MarkPosition) -> CGPoint {
        return CGPoint(x: (pos.proximal.x + pos.distal.x) / 2.0, y: (pos.proximal.y + pos.distal.y) / 2.0)
    }

    /// Returns true if target is a Mac, false for iOS.
    static func isRunningOnMac() -> Bool {
        #if targetEnvironment(macCatalyst)
            return true
        #else
            return false
        #endif
    }

    // Measures shortest distance from a line defined by two points and a point.
    static func distance(linePoint1: CGPoint, linePoint2: CGPoint, point: CGPoint) -> CGFloat {
        var numerator = (linePoint2.y - linePoint1.y) * point.x - (linePoint2.x - linePoint1.x) * point.y + linePoint2.x * linePoint1.y - linePoint2.y * linePoint1.x
        numerator = abs(numerator)
        var denominator = pow((linePoint2.y - linePoint1.y), 2) + pow((linePoint2.x - linePoint1.x), 2)
        denominator = sqrt(denominator)
        return numerator / denominator
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
