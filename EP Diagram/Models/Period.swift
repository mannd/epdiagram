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

struct Period: Equatable, Hashable {
    private(set) var id = UUID()
    
    var name: String = "NEW PERIOD"
    var duration: CGFloat = 500
    var color: UIColor = Preferences.defaultPeriodColor
    var resettable: Bool = false
    var offset: Int = 0
}

extension Period {
    /// Tests to see if a period is similar to another period, i.e. identical except for id.
    /// - Parameter period: Period to be tested for similarity
    /// - Returns: True if periods similar
    func isSimilarTo(period: Period) -> Bool {
        return name == period.name
                && duration == period.duration
                && color == period.color
                && resettable == period.resettable
                && offset == period.offset
    }

    /// Tests to see if two arrays of Period are similar.
    ///
    /// Arrays with different counts are not similar.  Two empty arrays are similar.
    /// - Parameters:
    ///   - p1: First array of Period
    ///   - p2: Second array of Period
    /// - Returns: True if arrays are similar
    static func periodsAreSimilar(_ p1: [Period], _ p2: [Period]) -> Bool {
        guard p1.count == p2.count else { return false }
        for i in 0..<p1.count {
            if !p1[i].isSimilarTo(period: p2[i]) {
                return false
            }
        }
        return true
    }
}

extension Period: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case duration
        case color
        case resettable
        case offset
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)
        duration = try CGFloat(container.decode(Float.self, forKey: .duration))
        resettable = try Bool(container.decode(Bool.self, forKey: .resettable))
        offset = try container.decode(Int.self, forKey: .offset)

        let colorData = try container.decode(Data.self, forKey: .color)
        color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) ?? UIColor.black
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(duration, forKey: .duration)
        try container.encode(resettable, forKey: .resettable)
        try container.encode(offset, forKey: .offset)

        let colorData = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
        try container.encode(colorData, forKey: .color)
    }
}

final class PeriodsModelController: ObservableObject {
    @Published var periods: [Period] = []

    init(periods: [Period]) {
        self.periods = periods
    }
}
