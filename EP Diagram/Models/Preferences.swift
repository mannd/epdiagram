//
//  Preferences.swift
//  EP Diagram
//
//  Created by David Mann on 6/6/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import SwiftUI

struct Preferences {
    // keys
    static let lineWidthKey = "defaultLineWidthKey"
    static let cursorLineWidthKey = "defaultCursorLineWidthKey"
    static let caliperLineWidthKey = "defaultCaliperLineWidthKey"
    static let showImpulseOriginKey = "defaultShowImpuseOriginKey"
    static let impulseOriginContiguousKey = "defaultImpulseOriginContiguousKey"
    static let impulseOriginLargeKey = "defaultImpulseOriginLargeKey"
    static let showBlockKey = "defaultShowBlockKey"
    static let showIntervalsKey = "defaultShowIntervalsKey"
    static let showArrowsKey = "defaultShowArrowsKey"
    static let showConductionTimesKey = "defaultShowConductionTimesKey"
    static let snapMarksKey = "defaultSnapMarksKey"
    static let linkMarksKey = "defaultLinkMarksKey"
    static let markStyleKey = "defaultMarkStyleKey"
    static let labelDescriptionVisibilityKey = "defaultLabelDescriptionVisibilityKey"
    static let leftMarginKey = "defaultLeftMarginKey"
    static let playSoundsKey = "defaultPlaySoundsKey"
    static let hideMarksKey = "defaultHideMarksKey"
    static let doubleLineBlockMarkerKey = "defaultDoubleLineBlockMarkerKey"
    static let rightAngleBlockMarkerKey = "defaultRightAngleBlockMarkerKey"
    static let showMarkersKey = "defaultShowMarkersKey"
    static let hideZeroCTKey = "defaultHideZeroCTKey"
    static let markerLineWidthKey = "defaultMarkerLineWidthKey"
    static let showMarkLabelsKey = "defaultShowMarkLabelsKey"
    static let showPeriodsKey = "defaultShowPeriodsKey"
    static let periodPositionKey = "defaultPeriodPositionKey"
    static let periodTransparencyKey = "defaultPeriodTransparencyKey"
    static let declutterIntervalsKey = "defaultDeclutterIntervalskey"

    // keys not modifiable by user
    static let notFirstRunKey = "defaultNotFirstRunKey"
    static let versionKey = "defaultVersionKey"
    static let imageViewHeightKey = "defaultImageViewHeight"

    // color keys
    static let caliperColorNameKey = "defaultCaliperColorNameKey"
    static let cursorColorNameKey = "defaultCursorColorNameKey"
    static let attachedColorNameKey = "defaultAttachedColorNameKey"
    static let connectedColorNameKey = "defaultConnectedColorNameKey"
    static let selectedColorNameKey = "defaultSelectedColorNameKey"
    static let linkedColorNameKey = "defaultLinkedColorNameKey"
    static let activeColorNameKey = "defaultActiveColorNameKey"
    static let markerColorNameKey = "defaultMarkerColorNameKey"
    static let periodColorNameKey = "defaultPeriodColorNameKey"

    // Stored as Int, converted to CGFloat when used.
    static var markLineWidth: Int = 2
    static var cursorLineWidth: Int = 1
    static var showImpulseOrigin = true
    static var impulseOriginContiguous = false
    static var impulseOriginLarge = false
    static var showBlock = true
    static var showArrows = false
    static var showIntervals = true
    static var showConductionTimes = true
    static var snapMarks = true
    static var markStyle = Mark.Style.solid.rawValue
    static var labelDescriptionVisibility = TextVisibility.invisible.rawValue
    static var leftMargin: Double = 50
    static var playSounds: Bool = true
    static var hideMarks: Bool = false
    static var caliperLineWidth: Int = 1
    static var doubleLineBlockMarker: Bool = true
    static var rightAngleBlockMarker: Bool = false
    static var showMarkers: Bool = false
    static var hideZeroCT: Bool = false
    static var markerLineWidth: Int = 2
    static var showMarkLabels: Bool = true
    static var showPeriods: Bool = false
    static var periodPosition = PeriodPosition.bottom.rawValue
    static var periodTransparency: CGFloat = 1.0
    static var declutterIntervals: Bool = false
    static var imageViewHeight: CGFloat = 0.5

    // default Colors
    static let defaultActiveColor = UIColor.systemRed
    static let defaultCursorColor = UIColor.systemBlue
    static let defaultCaliperColor = UIColor.systemBlue
    static let defaultAttachedColor = UIColor.systemOrange
    static let defaultConnectedColor = UIColor.systemGreen
    static let defaultSelectedColor = UIColor.systemBlue
    static let defaultLinkedColor = UIColor.systemPurple
    static let defaultMarkerColor = UIColor.systemBlue
    static let defaultPeriodColor = UIColor.systemGreen

    // Color names
    static var caliperColorName: String = defaultCaliperColor.toString
    static var cursorColorName: String = defaultCursorColor.toString
    static var attachedColorName: String = defaultAttachedColor.toString
    static var connectedColorName: String = defaultConnectedColor.toString
    static var selectedColorName: String = defaultSelectedColor.toString
    static var linkedColorName: String = defaultLinkedColor.toString
    static var activeColorName: String = defaultActiveColor.toString
    static var markerColorName: String = defaultMarkerColor.toString
    static var periodColorName: String = defaultPeriodColor.toString

    /// Default preferences, set at app startup
    static func defaults() -> [String: Any] {
        let defaultPreferences: [String: Any] = [
            Preferences.lineWidthKey: Preferences.markLineWidth,
            Preferences.cursorLineWidthKey: Preferences.cursorLineWidth,
            Preferences.showImpulseOriginKey: Preferences.showImpulseOrigin,
            Preferences.showBlockKey: Preferences.showBlock,
            Preferences.showIntervalsKey: Preferences.showIntervals,
            Preferences.showConductionTimesKey: Preferences.showConductionTimes,
            Preferences.snapMarksKey: Preferences.snapMarks,
            Preferences.markStyleKey: Preferences.markStyle,
            Preferences.labelDescriptionVisibilityKey: Preferences.labelDescriptionVisibility,
            Preferences.leftMarginKey: Preferences.leftMargin,
            Preferences.playSoundsKey: Preferences.playSounds,
            Preferences.hideMarksKey: Preferences.hideMarks,
            Preferences.caliperLineWidthKey: Preferences.caliperLineWidth,
            Preferences.caliperColorNameKey: Preferences.caliperColorName,
            Preferences.cursorColorNameKey: Preferences.cursorColorName,
            Preferences.attachedColorNameKey: Preferences.attachedColorName,
            Preferences.connectedColorNameKey: Preferences.connectedColorName,
            Preferences.selectedColorNameKey: Preferences.selectedColorName,
            Preferences.linkedColorNameKey: Preferences.linkedColorName,
            Preferences.activeColorNameKey: Preferences.activeColorName,
            Preferences.showArrowsKey: Preferences.showArrows,
            Preferences.doubleLineBlockMarkerKey: Preferences.doubleLineBlockMarker,
            Preferences.rightAngleBlockMarkerKey: Preferences.rightAngleBlockMarker,
            Preferences.showMarkersKey: Preferences.showMarkers,
            Preferences.hideZeroCTKey: Preferences.hideZeroCT,
            Preferences.markerLineWidthKey: Preferences.markerLineWidth,
            Preferences.markerColorNameKey: Preferences.markerColorName,
            Preferences.showMarkLabelsKey: Preferences.showMarkLabels,
            Preferences.showPeriodsKey: Preferences.showPeriods,
            Preferences.periodPositionKey: Preferences.periodPosition,
            Preferences.periodColorNameKey: Preferences.periodColorName,
            Preferences.periodTransparencyKey: Preferences.periodTransparency,
            Preferences.declutterIntervalsKey: Preferences.declutterIntervals,
            Preferences.impulseOriginContiguousKey: Preferences.impulseOriginContiguous,
            Preferences.impulseOriginLargeKey: Preferences.impulseOriginLarge,
            Preferences.imageViewHeightKey: Preferences.imageViewHeight,
        ]
        return defaultPreferences
    }
}

