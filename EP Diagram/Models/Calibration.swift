//
//  Calibration.swift
//  EP Diagram
//
//  Created by David Mann on 6/30/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

// Must be a class, reference to calibration is shared by ladder and cursor views.
final class Calibration: Codable, CustomDebugStringConvertible {
    var debugDescription: String {
        """
        Calibration:
          originalZoom = \(originalZoom)
          currentZoom = \(currentZoom)
          originalCalFactor = \(originalCalFactor)
          currentCalFactor = \(currentCalFactor)
          isCalibrated = \(isCalibrated)
        """
    }

    var originalZoom: CGFloat = 1
    var currentZoom: CGFloat = 1
    var originalCalFactor: CGFloat = 1
    var isCalibrated = false

    // TODO: make private after deprecated set removed
    static let standardInterval: CGFloat = 1000

    var currentCalFactor: CGFloat {
        (originalZoom * originalCalFactor) / currentZoom
    }

    @available(*, deprecated, message: "Can be removed after after further testing.")
    func set(zoom: CGFloat, calFactor: CGFloat) {
        originalZoom = zoom
        currentZoom = zoom
        originalCalFactor = calFactor
        isCalibrated = true
    }

    func set(zoom: CGFloat, value: CGFloat) {
        originalZoom = zoom
        currentZoom = zoom
        originalCalFactor = Self.standardInterval / value
        isCalibrated = true
    }

}
