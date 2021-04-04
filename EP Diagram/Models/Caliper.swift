//
//  Caliper.swift
//  EP Diagram
//
//  Created by David Mann on 7/2/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

/// A caliper that is used to calibrate a diagram.  It has move limited functionality than the
/// calipers in **EP Calipers**, because its role is more limited.
struct Caliper {
    enum Component {
        case bar1, bar2, crossbar
    }
    var bar1Position: CGFloat = 0
    var bar2Position: CGFloat = 0
    var crossbarPosition: CGFloat = 0

    var value: CGFloat { abs(bar1Position - bar2Position) }

    var minY: CGFloat = 0
    var maxY: CGFloat = 0

    let measureText: String = L("Measure")
    let text: String = L("1000 msec")
    let boundary: CGFloat = 10

    var isVisible: Bool = false
    var color: UIColor = UIColor.systemBlue
    var lineWidth: CGFloat = 1

    /// Determines if a point is near a caliper component.
    ///
    /// Note that this function tests the components in a set order, which will affect which component
    /// is returned if a point is close to more than one component.
    /// - Parameters:
    ///   - p: a `CGPoint`
    ///   - accuracy: how close the point needs to be to be considered nearby
    /// - Returns: `Component` that point is near to, or `nil` if no component is nearby
    func isNearCaliperComponent(point p: CGPoint, accuracy: CGFloat) -> Component? {
        guard p.y >= minY && p.y <= maxY else { return nil }
        if abs(p.x - bar1Position) < accuracy { return .bar1 }
        if abs(p.x - bar2Position) < accuracy { return .bar2}
        if abs(p.y - crossbarPosition) < accuracy { return .crossbar }
        return nil
    }

    /// Determines if a point is near any part of the caliper.
    /// - Parameters:
    ///   - p: a `CGPoint`
    ///   - accuracy: how close the point needs to be to be considere nearby
    /// - Returns: true if the point is nearby, otherwise false
    func isNearCaliper(point p: CGPoint, accuracy: CGFloat) -> Bool {
        return isNearCaliperComponent(point: p, accuracy: accuracy) != nil
    }

    /// Move caliper component by delta.
    /// - Parameters:
    ///   - delta: a `CGPoint` representing the difference between the component position and the new position
    ///   - component: a caliper `Component`
    mutating func move(delta: CGPoint, component: Component) {
        switch component {
        case .bar1:
            bar1Position += delta.x
        case .bar2:
            bar2Position += delta.x
        case .crossbar:
            bar1Position += delta.x
            bar2Position += delta.x
            // FIXME: this doesn't do what you think it does.  See failing test.
            if delta.y < 0 {
                crossbarPosition += (crossbarPosition >= minY + boundary ? delta.y : 0)
            } else {
                crossbarPosition += (crossbarPosition <= maxY - boundary ? delta.y : 0)
            }
        }
    }
}
