//
//  Common.swift
//  EP Diagram
//
//  Created by David Mann on 7/24/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

/// Namespace for global static functions, variables.
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

    // Note we purposely ignore crossed segments here, we don't want them to reported as 0 distance.
    static func distance(fromSegment s1: Segment, toSegment s2: Segment) -> CGFloat {
        let min1 = min(distanceSegmentToPoint(segment: s1, point: s2.proximal),
                       distanceSegmentToPoint(segment: s1, point: s2.distal))
        let min2 = min(distanceSegmentToPoint(segment: s2, point: s1.proximal),
                       distanceSegmentToPoint(segment: s2, point: s1.distal))
        return min(min1, min2)
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

    // Algorithm from: https://stackoverflow.com/questions/15690103/intersection-between-two-lines-in-coordinates
    // Returns intersection point of two line segments, nil if no intersection.
    static func getIntersection(ofLineFrom p1: CGPoint, to p2: CGPoint, withLineFrom p3: CGPoint, to p4: CGPoint) -> CGPoint? {
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

    static func isIPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // UI alerts
    static func showMessage(viewController: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: L("OK"), style: .cancel, handler: nil)
        alert.addAction(okAction)
        viewController.present(alert, animated: true)
    }

    static func showWarning(viewController: UIViewController, title: String, message: String, okActionButtonTitle: String = L("OK"), action: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: okActionButtonTitle, style: .destructive, handler: action)
        let cancelAction = UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        viewController.present(alert, animated: true)
    }

    static func showFileError(viewController: UIViewController, error: Error) {
        showMessage(viewController: viewController, title: L("File Error"), message: L("Error: \(error.localizedDescription)"))
    }

    static func showTextAlert(viewController vc: UIViewController, title: String, message: String, placeholder: String? = nil, preferredStyle: UIAlertController.Style, handler: ((String) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        alert.addAction(UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil))
        alert.addTextField { textField in
            if let placeholder = placeholder {
                textField.placeholder = placeholder
            }
        }
        alert.addAction(UIAlertAction(title: L("Save"), style: .default) { action in
            if let text = alert.textFields?.first?.text {
                if let handler = handler {
                    handler(text)
                }
            }
        })
        vc.present(alert, animated: true)
    }

    static func showNameDiagramAlert(viewController vc: UIViewController, diagram: Diagram, handler: ((String, String) -> Void)?) {
        let alert = UIAlertController(title: L("Name Diagram"), message: L("Give a name and optional description to this diagram"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil))
        alert.addTextField { textField in
            textField.placeholder = L("Diagram name")
            textField.text = diagram.name
        }
        alert.addTextField { textField in
            textField.placeholder = L("Diagram description")
            textField.text = diagram.description
        }
        alert.addAction(UIAlertAction(title: L("Save"), style: .default) { action in
            if let name = alert.textFields?.first?.text, let description = alert.textFields?[1].text {
                if let handler = handler {
                    handler(name, description)
                }
                else {
                    P("name = \(name), description = \(description)")
                }
            }
        })
        vc.present(alert, animated: true)
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

