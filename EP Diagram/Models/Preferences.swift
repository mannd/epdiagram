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
    static let defaultShowImpulseOriginKey = "defaultShowImpuseOriginKey"
    static let defaultShowBlockKey = "defaultShowBlockKey"

    // Stored as Int, converted to CGFloat when used.
    var lineWidth: Int = 2
    var showImpulseOrigin = false
    var showBlock = true
//    var red = UIColor.systemRed
//    var blue = UIColor.systemBlue
//    var unhighlightedColor = UIColor.label
//    var attachedColor = UIColor.systemOrange
//    var linkColor = UIColor.systemGreen
//    var selectedColor = UIColor.systemRed
//    var groupedColor = UIColor.systemPurple
//    var markLineWidth: CGFloat = 2
//    var connectedLineWidth: CGFloat = 4
//    var showPivots = false

    func save() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(lineWidth, forKey: Preferences.defaultLineWidthKey)
        userDefaults.set(showImpulseOrigin, forKey: Preferences.defaultShowImpulseOriginKey)
        userDefaults.set(showBlock, forKey: Preferences.defaultShowBlockKey)


    }

    mutating func retrieve() {
        let userDefaults = UserDefaults.standard
        lineWidth = userDefaults.integer(forKey: Preferences.defaultLineWidthKey)
        showImpulseOrigin = userDefaults.bool(forKey: Preferences.defaultShowImpulseOriginKey)
        showBlock = userDefaults.bool(forKey: Preferences.defaultShowBlockKey)
    }
    
}
