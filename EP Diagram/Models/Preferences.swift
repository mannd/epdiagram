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
    static let defaultPlaySoundsKey = "defaultPlaySoundsKey"
    static let defaultHideMarksKey = "defaultHideMarksKey"
    static let defaultCaliperLineWidthKey = "defaultCaliperLineWidthKey"
    static let defaultCaliperColorNameKey = "defaultCaliperColorNameKey"
    static let defaultCursorColorNameKey = "defaultCursorColorNameKey"
    static let defaultAttachedColorNameKey = "defaultAttachedColorNameKey"
    static let defaultConnectedColorNameKey = "defaultConnectedColorNameKey"
    static let defaultSelectedColorNameKey = "defaultSelectedColorNameKey"
    static let defaultLinkedColorNameKey = "defaultLinkedColorNameKey"
    static let defaultNormalColorNameKey = "defaultNormalColorNameKey"
    static let defaultActiveColorNameKey = "defaultActiveColorNameKey"

    // Stored as Int, converted to CGFloat when used.
    static var markLineWidth: Int = 2
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
    static var caliperColorName: Int = ColorName.blue.rawValue
    static var cursorColorName: Int = ColorName.blue.rawValue
    static var attachedColorName: Int = ColorName.orange.rawValue
    static var connectedColorName: Int = ColorName.green.rawValue
    static var selectedColorName: Int = ColorName.blue.rawValue
    static var linkedColorName: Int = ColorName.purple.rawValue
    static var normalColorName: Int = ColorName.normal.rawValue
    static var activeColorName: Int = ColorName.red.rawValue

    static func defaults() -> [String: Any] {
        let defaultPreferences: [String: Any] = [
            Preferences.defaultLineWidthKey: Preferences.markLineWidth,
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
            Preferences.defaultCaliperColorNameKey: Preferences.caliperColorName,
            Preferences.defaultCursorColorNameKey: Preferences.cursorColorName,
            Preferences.defaultAttachedColorNameKey: Preferences.attachedColorName,
            Preferences.defaultConnectedColorNameKey: Preferences.connectedColorName,
            Preferences.defaultSelectedColorNameKey: Preferences.selectedColorName,
            Preferences.defaultLinkedColorNameKey: Preferences.linkedColorName,
            Preferences.defaultNormalColorNameKey: Preferences.normalColorName,
            Preferences.defaultActiveColorNameKey: Preferences.activeColorName,
        ]
        return defaultPreferences
    }
}

enum ColorName: Int, Codable {
    case blue
    case red
    case yellow
    case green
    case purple
    case orange
    case normal // black in light mode, white in dark mode
    case pink

    static var colorMap: Dictionary<ColorName, UIColor> = [
        .blue: UIColor.systemBlue,
        .red: UIColor.systemRed,
        .yellow: UIColor.systemYellow,
        .green: UIColor.systemGreen,
        .purple: UIColor.systemPurple,
        .orange: UIColor.systemOrange,
        .normal: UIColor.label,
        .pink: UIColor.systemPink
    ]

    func color() -> UIColor {
        return ColorName.colorMap[self] ?? .blue
    }
}
