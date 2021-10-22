//
//  LadderTemplate.swift
//  EP Diagram
//
//  Created by David Mann on 5/16/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

/// A template from which a Ladder can be created (copied).
struct LadderTemplate: Codable, Equatable {
    private(set) var id = UUID()

    var name: String = ""
    var description: String = ""
    var leftMargin: CGFloat = 50
    var regionTemplates = [RegionTemplate]()

    // Returns a basic ladder (A, AV, V).
    static func defaultTemplate_A_AV_V() -> LadderTemplate {
        var ladderTemplate = LadderTemplate(name: "A-AV-V Ladder", description: "Basic ladder with commonly used regions")
        let aRegionTemplate = RegionTemplate(name: "A", description: "Atrium", unitHeight: 1)
        let avRegionTemplate = RegionTemplate(name: "AV", description: "Atrioventricular", unitHeight: 2)
        let vRegionTemplate = RegionTemplate(name: "V", description: "Ventricular", unitHeight: 1)
        ladderTemplate.regionTemplates.append(contentsOf: [aRegionTemplate, avRegionTemplate, vRegionTemplate])
        return ladderTemplate
    }

    static func defaultTemplate_SA_A_AVN_V() -> LadderTemplate {
        var ladderTemplate = LadderTemplate(name: "SA-A-AVN-V Ladder", description: "Ladder that includes SA region")
        let saRegionTemplate = RegionTemplate(name: "SA", description: "Sino-atrium", unitHeight: 1)
        let aRegionTemplate = RegionTemplate(name: "A", description: "Atrium", unitHeight: 2)
        let avnRegionTemplate = RegionTemplate(name: "AVN", description: "AV node", unitHeight: 2)
        let vRegionTemplate = RegionTemplate(name: "V", description: "Ventricular", unitHeight: 1)
        ladderTemplate.regionTemplates.append(contentsOf: [saRegionTemplate, aRegionTemplate, avnRegionTemplate, vRegionTemplate])
        return ladderTemplate
    }

    static func defaultTemplate_A_AVN_H_V() -> LadderTemplate {
        var ladderTemplate = LadderTemplate(name: "A-AVN-H-V Ladder", description: "Ladder that includes His region")
        let aRegionTemplate = RegionTemplate(name: "A", description: "Atrium", unitHeight: 2)
        let avnRegionTemplate = RegionTemplate(name: "AVN", description: "AV node", unitHeight: 4)
        let hisRegionTemplate = RegionTemplate(name: "H", description: "His", unitHeight: 1)
        let vRegionTemplate = RegionTemplate(name: "V", description: "Ventricular", unitHeight: 2)
        ladderTemplate.regionTemplates.append(contentsOf: [aRegionTemplate, avnRegionTemplate, hisRegionTemplate, vRegionTemplate])
        return ladderTemplate
    }

    static func defaultTemplate() -> LadderTemplate {
        return templates()[0]
    }

    static func defaultTemplates() -> [LadderTemplate] {
        return [defaultTemplate_A_AV_V(), defaultTemplate_SA_A_AVN_V(), defaultTemplate_A_AVN_H_V()]
    }

    static func templates() -> [LadderTemplate] {
        var ladderTemplates = FileIO.retrieve(FileIO.userTemplateFile, from: .documents, as: [LadderTemplate].self) ?? LadderTemplate.defaultTemplates()
        if ladderTemplates.isEmpty {
            ladderTemplates = LadderTemplate.defaultTemplates()
        }
        return ladderTemplates
    }
}
