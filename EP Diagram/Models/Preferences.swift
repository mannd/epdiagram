//
//  Preferences.swift
//  EP Diagram
//
//  Created by David Mann on 6/6/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

// TODO: remember to register each new user default in AppDelegate()!
struct Preferences {
    // keys
    static let defaultLineWidthKey = "defaultLineWidthKey"
    static let defaultCursorLineWidthKey = "defaultCursorLineWidthKey"
    static let defaultShowImpulseOriginKey = "defaultShowImpuseOriginKey"
    static let defaultShowBlockKey = "defaultShowBlockKey"
    static let defaultShowIntervalsKey = "defaultShowIntervalsKey"
    static let defaultShowConductionTimesKey = "defaultShowConductionTimesKey"
    static let defaultSnapMarksKey = "defaultSnapMarksKey"
    static let defaultLinkMarksKey = "defaultLinkMarksKey"
    static let defaultMarkStyleKey = "defaultMarkStyleKey"
    static let defaultLabelDescriptionVisibilityKey = "defaultLabelDescriptionVisibilityKey"
    static let defaultLeftMarginKey = "defaultLeftMarginKey"
    static let defaultCaliperColorKey = "defaultCaliperColorKey"
    static let defaultPlaySoundsKey = "defaultPlaySoundsKey"
    static let defaultHideMarksKey = "defaultHideMarksKey"
    static let defaultCaliperLineWidthKey = "defaultCaliperLineWidthKey"

    // Stored as Int, converted to CGFloat when used.
    static var lineWidth: Int = 2
    static var cursorLineWidth: Int = 1
    static var showImpulseOrigin = false
    static var showBlock = false
    static var showIntervals = true
    static var showConductionTimes = true
    static var snapMarks = true
    static var markStyle = Mark.Style.solid.rawValue
    static var labelDescriptionVisibility = TextVisibility.invisible.rawValue
    static var leftMargin: Double = 50
    static var playSounds: Bool = true
    static var hideMarks: Bool = false
    static var caliperLineWidth: Int = 1

    static func defaults() -> [String: Any] {
        let defaultPreferences: [String: Any] = [
            Preferences.defaultLineWidthKey: Preferences.lineWidth,
            Preferences.defaultCursorLineWidthKey: Preferences.cursorLineWidth,
            Preferences.defaultShowImpulseOriginKey: Preferences.showImpulseOrigin,
            Preferences.defaultShowBlockKey: Preferences.showBlock,
            Preferences.defaultShowIntervalsKey: Preferences.showIntervals,
            Preferences.defaultShowConductionTimesKey: Preferences.showConductionTimes,
            Preferences.defaultSnapMarksKey: Preferences.snapMarks,
            Preferences.defaultMarkStyleKey: Preferences.markStyle,
            Preferences.defaultLabelDescriptionVisibilityKey: Preferences.labelDescriptionVisibility,
            Preferences.defaultLeftMarginKey: Preferences.leftMargin,
            Preferences.defaultPlaySoundsKey: Preferences.playSounds,
            Preferences.defaultHideMarksKey: Preferences.hideMarks,
            Preferences.defaultCaliperLineWidthKey: Preferences.caliperLineWidth,
        ]
        return defaultPreferences
    }
}

// Possibly use to add colors to user defaults...
// From https://gist.github.com/HassanElDesouky/373bcf4f1002f77557814a3e24fa4759
extension UserDefaults {
  func colorForKey(key: String) -> UIColor? {
    var colorReturnded: UIColor?
    if let colorData = data(forKey: key) {
      do {
        if let color = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
          colorReturnded = color
        }
      } catch {
        print("Error UserDefaults")
      }
    }
    return colorReturnded
  }

  func setColor(color: UIColor?, forKey key: String) {
    var colorData: NSData?
    if let color = color {
      do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) as NSData?
        colorData = data
      } catch {
        print("Error UserDefaults")
      }
    }
    set(colorData, forKey: key)
  }
}
