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
    static let defaultGroupMarksKey = "defaultGroupMarksKey"


    // Stored as Int, converted to CGFloat when used.
    static var lineWidth: Int = 2
    static var cursorLineWidth: Int = 1
    static var showImpulseOrigin = false
    static var showBlock = false
    static var showIntervals = true
    static var showConductionTimes = true
    static var snapMarks = true
    
//    var red = UIColor.systemRed
//    var blue = UIColor.systemBlue
//    var unhighlightedColor = UIColor.label
//    var attachedColor = UIColor.systemOrange
//    var linkColor = UIColor.systemGreen
//    var selectedColor = UIColor.systemRed
//    var groupedColor = UIColor.systemPurple
//    var showPivots = false
    
}
