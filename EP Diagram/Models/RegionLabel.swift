//
//  RegionLabel.swift
//  EP Diagram
//
//  Created by David Mann on 5/8/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import Foundation

// A RegionLabel is little more than just a label, but it might get fancier...
class RegionLabel {
    public var name: String
    public var selected: Bool = false
    // Use the cursor to mark markable regions.  E.g. atrium is markable, AV region is not.
    public var markable: Bool = true

    init(_ name: String) {
        self.name = name
    }
}
