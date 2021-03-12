//
//  Common.swift
//  EP Diagram
//
//  Created by David Mann on 7/24/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

/// Namespace for global static functions, variables.
enum Geometry {

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

    // Note we purposely ignore crossed segments here, we don't want them to reported as 0 distance.
    static func distance(fromSegment s1: Segment, toSegment s2: Segment) -> CGFloat {
        let min1 = min(distanceSegmentToPoint(segment: s1, point: s2.proximal),
                       distanceSegmentToPoint(segment: s1, point: s2.distal))
        let min2 = min(distanceSegmentToPoint(segment: s2, point: s1.proximal),
                       distanceSegmentToPoint(segment: s2, point: s1.distal))
        return min(min1, min2)
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

    // Algorithm from: https://stackoverflow.com/questions/15690103/intersection-between-two-lines-in-coordinates
    // Returns intersection point of two line segments, nil if no intersection.
    static func intersection(ofLineFrom p1: CGPoint, to p2: CGPoint, withLineFrom p3: CGPoint, to p4: CGPoint) -> CGPoint? {
        let d: CGFloat = (p2.x - p1.x) * (p4.y - p3.y) - (p2.y - p1.y) * (p4.x - p3.x)
        if d == 0 {
            return nil; // parallel lines
        }
        let u: CGFloat = ((p3.x - p1.x)*(p4.y - p3.y) - (p3.y - p1.y)*(p4.x - p3.x))/d
        let v: CGFloat = ((p3.x - p1.x)*(p2.y - p1.y) - (p3.y - p1.y)*(p2.x - p1.x))/d
        if u < 0.0 || u > 1.0 {
            return nil; // intersection point not between p1 and p2
        }
        if v < 0.0 || v > 1.0 {
            return nil; // intersection point not between p3 and p4
        }
        var intersection = CGPoint()
        intersection.x = p1.x + u * (p2.x - p1.x)
        intersection.y = p1.y + u * (p2.y - p1.y)
        return intersection
    }

    static func rightTriangleBase(withAngle angle: CGFloat, height: CGFloat) -> CGFloat {
        precondition(angle < 90)     // precondition, keep angle < 90 degrees
        return tan(angle.degreesToRadians) * abs(height)
    }

    static func oppositeAngle(p1: CGPoint, p2: CGPoint) -> CGFloat {
        precondition(p1.y != p2.y) // otherwise would divide by zero
        let sign: CGFloat = p2.x >=  p1.x ? 1 : -1
        let oppositeSideLength = p2.x - p1.x
        let adjacentSideLength = p2.y - p1.y
        let ratio = oppositeSideLength / adjacentSideLength
        return atan(ratio).radiansToDegrees * sign
    }

    static func areParallel(_ s1: Segment, _ s2: Segment) -> Bool {
        // exclude situation of vertical segments
        if s1.proximal.x == s1.distal.x {
            return s2.proximal.x == s2.distal.x ? true : false
        }
        let a1 = (s1.proximal.y - s1.distal.y) / (s1.proximal.x - s1.distal.x)
        let a2 = (s2.proximal.y - s2.distal.y) / (s2.proximal.x - s2.distal.x)
        return nearlyEqual(Double(a1), Double(a2))
//        return a1 == a2
    }

    // Doesn't check for y outside of segment.  Exclude horizontal line before calling.
    static func evaluateX(knowingY y: CGFloat, fromSegment s: Segment) -> CGFloat {
        precondition(s.proximal.y != s.distal.y)
        let x1 = s.proximal.x
        let y1 = s.proximal.y
        let x2 = s.distal.x
        let y2 = s.distal.y
        let x = ((x2-x1) * (y-y1)/(y2-y1)) + x1
        return x
    }

    static func nearlyEqual(_ a: Double, _ b: Double) -> Bool {
        return abs(a - b) < Double.ulpOfOne
    }
}

extension FloatingPoint {
    var degreesToRadians: Self { self * .pi / 180 }
    var radiansToDegrees: Self { self * 180 / .pi }
}

