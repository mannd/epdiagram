//
//  Calibration.swift
//  EP Diagram
//
//  Created by David Mann on 6/30/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

/// Calibration is used to convert distances between marks into measurements in msec.
/// A calFactor  is determined that is a ratio of msec to screen points.  Calibration adjusts automatically
/// to zoom scale.
final class Calibration: Codable {
    // NOTE: Calibration must be a class, as a reference to
    // calibration is shared by ladder and cursor views.
    var originalZoom: CGFloat = 1
    var currentZoom: CGFloat = 1
    var originalCalFactor: CGFloat = 1
    var isCalibrated = false

    static private let standardInterval: CGFloat = 1000

    var currentCalFactor: CGFloat {
        (originalZoom * originalCalFactor) / currentZoom
    }

    func set(zoom: CGFloat, value: CGFloat) {
        originalZoom = zoom
        currentZoom = zoom
        originalCalFactor = Self.standardInterval / value
        isCalibrated = true
    }

}

extension Calibration: CustomDebugStringConvertible {
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
}
