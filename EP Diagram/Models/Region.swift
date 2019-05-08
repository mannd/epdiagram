//
//  Region.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import Foundation

class Region {
    public var startPosition: Double?
    public var endPosition: Double?
    public var selected: Bool = false
    public var label: RegionLabel?
    public var marks: [Mark]?
}
