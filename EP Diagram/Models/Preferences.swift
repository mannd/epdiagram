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

    // Stored as Int, converted to CGFloat when used.
    static var lineWidth: Int = 2
    static var cursorLineWidth: Int = 1
    static var showImpulseOrigin = false
    static var showBlock = false
    static var showIntervals = true
    static var showConductionTimes = true
    static var snapMarks = true
    static var markStyle = Mark.Style.solid.rawValue

    // TODO: Update when new prefs added.
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
        ]
        return defaultPreferences
    }
}
