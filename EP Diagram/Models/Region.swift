//
//  Region.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import Foundation

// A Region is a collection of Marks, in left to right order.  Positions are
// vertical, i.e. Y axis.  A Region has a RegionLabel such as "A" or "AV."
class Region {
    public var startPosition: Double?
    public var endPosition: Double?
    public var selected: Bool = false
    public var label: RegionLabel?
    public var marks: [Mark] = []
    public var markable: Bool = true
    public var decremental: Bool = false

    public func appendMark(_ mark: Mark) {
        marks.append(mark)
    }
}
