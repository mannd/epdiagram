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

// FIXME: dilemma.  If each period has a separate id, we cannot detect identical periods.
struct Period: Equatable {
    private(set) var id = UUID()
    
    var name: String = "NEW PERIOD"
    var duration: CGFloat = 500
    var color: UIColor = Preferences.defaultPeriodColor
    var resettable: Bool = false
}

extension Period: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case duration
        case color
        case resettable
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        duration = try CGFloat(container.decode(Float.self, forKey: .duration))
        resettable = try Bool(container.decode(Bool.self, forKey: .resettable))

        let colorData = try container.decode(Data.self, forKey: .color)
        color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor ?? UIColor.black
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(duration, forKey: .duration)
        try container.encode(resettable, forKey: .resettable)

        let colorData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        try container.encode(colorData, forKey: .color)
    }
}
