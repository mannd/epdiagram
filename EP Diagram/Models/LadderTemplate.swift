//
//  LadderTemplate.swift
//  EP Diagram
//
//  Created by David Mann on 5/16/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

struct LadderTemplate: Codable {
    var name: String = ""
    var description: String = ""
    var regionTemplates = [RegionTemplate]()
    let id = UUID()

    // Returns a basic ladder (A, AV, V).
    static func defaultTemplate() -> LadderTemplate {
        var ladderTemplate = LadderTemplate(name: "A-AV-V Ladder", description: "Basic ladder with commonly used regions")
        let aRegionTemplate = RegionTemplate(name: "A", description: "Atrium", unitHeight: 1)
        let avRegionTemplate = RegionTemplate(name: "AV", description: "Atrioventricular", unitHeight: 2)
        let vRegionTemplate = RegionTemplate(name: "V", description: "Ventricular", unitHeight: 1)
        ladderTemplate.regionTemplates.append(contentsOf: [aRegionTemplate, avRegionTemplate, vRegionTemplate])
        return ladderTemplate
    }

    static func defaultTemplate2() -> LadderTemplate {
        var ladderTemplate = LadderTemplate(name: "SA-A-AVN-V Ladder", description: "Ladder that includes SA region")
        let saRegionTemplate = RegionTemplate(name: "SA", description: "Sino-atrium", unitHeight: 1)
        let aRegionTemplate = RegionTemplate(name: "A", description: "Atrium", unitHeight: 2)
        let avnRegionTemplate = RegionTemplate(name: "AVN", description: "AV node", unitHeight: 2)
        let vRegionTemplate = RegionTemplate(name: "V", description: "Ventricular", unitHeight: 1)
        ladderTemplate.regionTemplates.append(contentsOf: [saRegionTemplate, aRegionTemplate, avnRegionTemplate, vRegionTemplate])
        return ladderTemplate
    }
}
