//
//  RegionTemplate.swift
//  EP Diagram
//
//  Created by David Mann on 5/16/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

struct RegionTemplate: Codable, Equatable, Hashable {
    var name: String = ""
    var description: String = ""
    var unitHeight: Int = 1
    var lineStyle: Mark.Style = .solid
    private(set) var id = UUID()
}
