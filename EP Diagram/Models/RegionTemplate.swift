//
//  RegionTemplate.swift
//  EP Diagram
//
//  Created by David Mann on 5/16/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

/// A template from which a Region can be created (copied).
struct RegionTemplate: Codable, Equatable, Hashable {
    var name: String = ""
    var description: String = ""
    var unitHeight: Int = 1
    var style: Mark.Style = .inherited
    private(set) var id = UUID()
}
