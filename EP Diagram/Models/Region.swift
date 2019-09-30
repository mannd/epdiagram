//
//  Region.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

// The two parts of a Region.
enum RegionSection {
    case labelSection
    case markSection
}

// A Region is a collection of Marks, in left to right order.  Positions are
// vertical, i.e. Y axis.  A Region has a labelSection such as "A" or "AV" and
// a markSection.
class Region {
    public var upperBoundary: CGFloat = 0
    public var lowerBoundary: CGFloat = 0
    public var selected: Bool = false
    public var name: String = ""
    public var marks: [Mark] = []
    public var markable: Bool = true
    public var decremental: Bool = false

    public func appendMark(_ mark: Mark) {
        marks.append(mark)
    }
    
}
