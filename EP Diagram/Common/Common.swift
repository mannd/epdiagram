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
    // PositionX translation
    static func translateToRegionPositionX(scaledViewPositionX: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return (scaledViewPositionX + offset) / scale
    }

    static func translateToScaledViewPositionX(regionPositionX: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
        return scale * regionPositionX - offset
    }

    // Position translation
    static func translateToRegionPosition(scaledViewPosition: CGPoint, region: Region, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToRegionPositionX(scaledViewPositionX: scaledViewPosition.x, offset: offset, scale: scale)
        let y = (scaledViewPosition.y - region.proximalBoundary) / region.height
        return CGPoint(x: x, y: y)
    }

    static func translateToScaledViewPosition(regionPosition: CGPoint, region: Region, offsetX offset: CGFloat, scale: CGFloat) -> CGPoint {
        let x = translateToScaledViewPositionX(regionPositionX: regionPosition.x, offset: offset, scale: scale)
        let y = region.proximalBoundary + regionPosition.y * region.height
        return CGPoint(x: x, y: y)
    }

    // Segment translation
    static func translateToScaledViewSegment(regionSegment: Segment, region: Region, offsetX offset: CGFloat, scale: CGFloat) -> Segment {
        return Segment(proximal: translateToScaledViewPosition(regionPosition: regionSegment.proximal, region: region, offsetX: offset, scale: scale), distal: translateToScaledViewPosition(regionPosition: regionSegment.distal, region: region, offsetX: offset, scale: scale))
    }

    static func translateToRegionSegment(scaledViewSegment: Segment, region: Region, offsetX offset: CGFloat, scale: CGFloat) -> Segment {
        return Segment(proximal: translateToRegionPosition(scaledViewPosition: scaledViewSegment.proximal, region: region, offsetX: offset, scale: scale), distal: translateToRegionPosition(scaledViewPosition: scaledViewSegment.distal, region: region, offsetX: offset, scale: scale))
    }

    // Agnostic math functions
    static func getSegmentMidpoint(_ segment: Segment) -> CGPoint {
        return CGPoint(x: (segment.proximal.x + segment.distal.x) / 2.0, y: (segment.proximal.y + segment.distal.y) / 2.0)
    }

    // Measures shortest distance from a line defined by two points and a point.
    // See https://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment
    static func distanceSegmentToPoint(segment: Segment, point p: CGPoint) -> CGFloat {
        func sqr(_ x: CGFloat) -> CGFloat { return x * x }
        func distanceSquared(p1: CGPoint, p2: CGPoint) -> CGFloat {
            return sqr(p1.x - p2.x) + sqr(p1.y - p2.y)
        }
        let v = segment.proximal
        let w = segment.distal
        let distSquared = distanceSquared(p1: v, p2: w)
        if distSquared == 0.0 {
            return distanceSquared(p1: p, p2: v)
        }
        var t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / distSquared
        t = max(0, min(1, t))
        let resultSquared = distanceSquared(p1: p, p2: CGPoint(x: v.x + t * (w.x - v.x), y: v.y + t * (w.y - v.y)))
        return sqrt(resultSquared)
    }

    static func distanceBetweenPoints(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        let diffX = p1.x - p2.x
        let diffY = p1.y - p2.y
        return sqrt(diffX * diffX + diffY * diffY)
    }

    // After https://math.stackexchange.com/questions/2193720/find-a-point-on-a-line-segment-which-is-the-closest-to-other-point-not-on-the-li
    static func closestPointOnSegmentToPoint(segment: Segment, point: CGPoint) -> CGPoint {
        let a = segment.proximal
        let b = segment.distal
        let p = point
        let v = CGPoint(x: b.x - a.x, y: b.y - a.y)
        let u = CGPoint(x: a.x - p.x, y: a.y - p.y)
        let vu = v.x * u.x + v.y * u.y
        let vv = v.x * v.x + v.y * v.y
        let t = -vu / vv
        if t >= 0 && t <= 1 {
            return vectorToSegment(t: t, p: CGPoint(x: 0, y: 0), a: a, b: b)
        }
        let g0 = sqDiag(p: vectorToSegment(t: 0, p: p, a: a, b: b))
        let g1 = sqDiag(p: vectorToSegment(t: 1, p: p, a: a, b: b))
        return g0 <= g1 ? a : b
    }

    static private func vectorToSegment(t: CGFloat, p: CGPoint, a: CGPoint, b: CGPoint) -> CGPoint {
        return CGPoint(x: (1 - t) * a.x + t * b.x - p.x, y: (1 - t) * a.y + t * b.y - p.y)
    }

    static private func sqDiag(p: CGPoint) -> CGFloat {
        return p.x * p.x + p.y * p.y
    }

    // Get x coordinate on segment, knowing endpoints and y coordinate.
    // See https://math.stackexchange.com/questions/149333/calculate-third-point-with-two-given-point
    static internal func getX(onSegment segment: Segment, fromY y: CGFloat) -> CGFloat? {
        let x0 = segment.proximal.x
        let x1 = segment.distal.x
        let y0 = segment.proximal.y
        let y1 = segment.distal.y
        // Avoid getting close to dividing by zero.
        guard abs(y1 - y0) > 0.001 else { return nil }
        // Give up if y is not along segment.
        guard y < max(y1, y0) && y > min(y1, y0) else { return nil }
        return ((x1 - x0) * (y - y0)) / (y1 - y0) + x0
    }

    // OS functions
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

