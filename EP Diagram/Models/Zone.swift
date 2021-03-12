//
//  Zone.swift
//  EP Diagram
//
//  Created by David Mann on 8/17/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

struct Zone: Codable {
    var regions: Set<Region> = []
    var startingRegion: Region?
    var start: CGFloat = 0
    var end: CGFloat = 0

    var isVisible: Bool = false
}
