//
//  Caliper.swift
//  EP Diagram
//
//  Created by David Mann on 7/2/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

struct Caliper {
    enum Component {
        case bar1, bar2, crossbar
    }
    var bar1Position: CGFloat = 0
    var bar2Position: CGFloat = 0
    var crossbarPosition: CGFloat = 0

    var value: CGFloat { abs(bar1Position - bar2Position) }

    var minY: CGFloat = 0
    var maxY: CGFloat?

    let measureText: String = L("Measure")
    let text: String = L("1000 msec")

    var isVisible: Bool = false

    func isNearCaliperComponent(point p: CGPoint, accuracy: CGFloat) -> Component? {
        guard let maxY = maxY else { return nil }
        guard p.y >= minY && p.y <= maxY else { return nil }
        if abs(p.x - bar1Position) < accuracy { return .bar1 }
        if abs(p.x - bar2Position) < accuracy { return .bar2}
        if abs(p.y - crossbarPosition) < accuracy { return .crossbar }
        return nil
    }

    func isNearCaliper(point p: CGPoint, accuracy: CGFloat) -> Bool {
        return isNearCaliperComponent(point: p, accuracy: accuracy) != nil
    }

    mutating func move(delta: CGPoint, component: Component) {
        switch component {
        case .bar1:
            bar1Position += delta.x
        case .bar2:
            bar2Position += delta.x
        case .crossbar:
            bar1Position += delta.x
            bar2Position += delta.x
            crossbarPosition += delta.y
        }
    }
}
