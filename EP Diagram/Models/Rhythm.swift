//
//  Rhythm.swift
//  EP Diagram
//
//  Created by David Mann on 3/5/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit

struct Rhythm {
    static let minimumCL: CGFloat = 50
    static let maximumCL: CGFloat = 2000
    static let minimumFibCL: CGFloat = 50
    static let maximumFibCL: CGFloat = 300

    let minimumCT: Double = 10
    let maximumCT: Double = Double(minimumCL) - 10

    var meanCL: CGFloat
    var regularity: Regularity
    var minCL: CGFloat
    var maxCL: CGFloat
    var randomizeImpulseOrigin: Bool
    var randomizeConductionTime: Bool
    var impulseOrigin: Mark.Endpoint
    var replaceExistingMarks: Bool
}

enum Regularity: Int, CustomStringConvertible, Identifiable, CaseIterable {
    case regular
    case fibrillation

    var id: Regularity { return self }

    var description: String {
        switch self {
        case .regular:
            return "Regular"
        case .fibrillation:
            return "Fibrillation"
        }
    }
}
