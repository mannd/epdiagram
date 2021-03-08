//
//  Rhythm.swift
//  EP Diagram
//
//  Created by David Mann on 3/5/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit

struct Rhythm {
    var meanCL: CGFloat
    var rhythmType: RhythmType
    var minCL: CGFloat
    var maxCL: CGFloat
    var randomizeCL: Bool
    var randomizeImpulseOrigin: Bool
    var randomizeConductionTime: Bool
    var replaceExistingMarks: Bool
}

enum RhythmType: Int, CustomStringConvertible, Identifiable, CaseIterable {
    case regular
    case fibrillation

    var id: RhythmType { return self }

    var description: String {
        switch self {
        case .regular:
            return "Regular"
        case .fibrillation:
            return "Fibrillation"
        }
    }
}
