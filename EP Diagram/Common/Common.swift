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
    static func translateToRegionPositionX(ladderViewPositionX: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return (ladderViewPositionX + offset) / scale
    }

    static func translateToLadderViewPositionX(regionPositionX: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return scale * regionPositionX - offset
    }

    static func translateToLadderViewPositionY(regionPositionY: CGFloat, regionProximalBoundary: CGFloat, regionHeight: CGFloat) -> CGFloat {
        return regionProximalBoundary + regionPositionY * regionHeight
    }

    static func translateToLadderViewPosition(regionPosition: CGPoint, regionProximalBoundary proxBoundary: CGFloat, regionHeight height: CGFloat, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToLadderViewPositionX(regionPositionX: regionPosition.x, offset: offset, scale: scale)
        let y = proxBoundary + regionPosition.y * height
        return CGPoint(x: x, y: y)
    }

    // Version just passing region.
    static func translateToLadderViewPosition(regionPosition: CGPoint, region: Region, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToLadderViewPositionX(regionPositionX: regionPosition.x, offset: offset, scale: scale)
        let y = region.proximalBoundary + regionPosition.y * region.height
        return CGPoint(x: x, y: y)
    }

    static func translateToScreenPosition(regionPosition: CGPoint, regionProximalBoundary proxBoundary: CGFloat, regionHeight height: CGFloat, offsetX: CGFloat, offsetY: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToLadderViewPositionX(regionPositionX: regionPosition.x, offset: offsetX, scale: scale)
        let y = proxBoundary + regionPosition.y * height + offsetY
        return CGPoint(x: x, y: y)
    }

    static func translateToLadderViewSegment(regionSegment: Segment, regionProximalBoundary proxBoundary: CGFloat, regionHeight height: CGFloat, offsetX offset: CGFloat, scale: CGFloat) -> Segment {
        return Segment(proximal: translateToLadderViewPosition(regionPosition: regionSegment.proximal, regionProximalBoundary: proxBoundary, regionHeight: height, offsetX: offset, scale: scale), distal: translateToLadderViewPosition(regionPosition: regionSegment.distal, regionProximalBoundary: proxBoundary, regionHeight: height, offsetX: offset, scale: scale))
    }

    static func translateToRegionPosition(ladderViewPosition: CGPoint, regionProximalBoundary proxBoundary: CGFloat, regionHeight height: CGFloat, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToRegionPositionX(ladderViewPositionX: ladderViewPosition.x, offset: offset, scale: scale)
        let y = (ladderViewPosition.y - proxBoundary) / height
        return CGPoint(x: x, y: y)
    }

    // Rect based translation function -- deprecated
    static func translateToScreenPosition(position: CGPoint, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToLadderViewPositionX(regionPositionX: position.x, offset: offset, scale: scale)
        let y = rect.origin.y + position.y * rect.height
        return CGPoint(x: x, y: y)
    }

    static func translateToRegionPosition(position: CGPoint, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToRegionPositionX(ladderViewPositionX: position.x, offset: offset, scale: scale)
        let y = (position.y - rect.origin.y) / rect.height
        return CGPoint(x: x, y: y)
    }

    static func translateToScreenSegment(regionSegment: Segment, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) -> Segment {
        return Segment(proximal: translateToScreenPosition(position: regionSegment.proximal, inRect: rect, offsetX: offset, scale: scale), distal: translateToScreenPosition(position: regionSegment.distal, inRect: rect, offsetX: offset, scale: scale))
    }

    static func translateToRegionSegment(screenSegment: Segment, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) -> Segment {
        return Segment(proximal: translateToRegionPosition(position: screenSegment.proximal, inRect: rect, offsetX: offset, scale: scale), distal: translateToRegionPosition(position: screenSegment.distal, inRect: rect, offsetX: offset, scale: scale))
    }
    static func getMidpoint(_ segment: Segment) -> CGPoint {
        return CGPoint(x: (segment.proximal.x + segment.distal.x) / 2.0, y: (segment.proximal.y + segment.distal.y) / 2.0)
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

    static func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let diffX = p1.x - p2.x
        let diffY = p1.y - p2.y
        return sqrt(diffX * diffX + diffY * diffY)
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
