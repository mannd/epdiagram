//
//  LadderTemplate.swift
//  EP Diagram
//
//  Created by David Mann on 5/16/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import Foundation

struct LadderTemplate: Codable {
    var name: String = ""
    var description: String = ""
    var regionTemplates = [RegionTemplate]()
    let id = UUID()

    // Returns a basic ladder (A, AV, V).
    static func defaultLadder() -> LadderTemplate {
        var ladderTemplate = LadderTemplate(name: "Default Ladder Template", description: "default ladder template")
        let aRegionTemplate = RegionTemplate(name: "A", description: "atrium", unitHeight: 1)
        let avRegionTemplate = RegionTemplate(name: "AV", description: "atrioventricular", unitHeight: 2)
        let vRegionTemplate = RegionTemplate(name: "V", description: "ventricular", unitHeight: 1)
        ladderTemplate.regionTemplates.append(contentsOf: [aRegionTemplate, avRegionTemplate, vRegionTemplate])
        return ladderTemplate
    }
}
