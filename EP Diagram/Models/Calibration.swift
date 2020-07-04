//
//  Calibration.swift
//  EP Diagram
//
//  Created by David Mann on 6/30/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

struct Calibration {
    var originalZoom: CGFloat = 1
    var currentZoom: CGFloat = 1
    var originalCalFactor: CGFloat = 1
    var isCalibrated: Bool = false

    var currentCalFactor: CGFloat {
        (originalZoom * originalCalFactor) / currentZoom
    }

    mutating func set(zoom: CGFloat, calFactor: CGFloat) {
        originalZoom = zoom
        currentZoom = zoom
        originalCalFactor = calFactor
    }

    mutating func reset() {
        originalZoom = 1
        currentZoom = 1
        // need below?
        //originalCalFactor = 1
    }

}
