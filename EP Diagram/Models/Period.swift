//
//  Period.swift
//  Period
//
//  Created by David Mann on 9/2/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit
import BetterCodable
import os.log

struct Period {

    var name: String = ""
    var duration: CGFloat = 0
    var color: UIColor = UIColor.green

    // height depends on Region height and number of Periods in the region.
}

extension Period: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case duration
        case color
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        duration = try CGFloat(container.decode(Float.self, forKey: .duration))

        let colorData = try container.decode(Data.self, forKey: .color)
        color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor ?? UIColor.black
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(duration, forKey: .duration)

        let colorData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        try container.encode(colorData, forKey: .color)
    }
}