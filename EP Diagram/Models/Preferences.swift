//
//  Preferences.swift
//  EP Diagram
//
//  Created by David Mann on 6/6/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

struct Preferences {
    // keys
    let defaultLineWidthKey = "defaultLineWidthKey"
    let defaultShowImpulseOriginKey = "defaultShowImpuseOriginKey"
    let defaultShowBlockKey = "defaultShowBlockKey"

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

    // TODO: write preferences to shared preferences.
    func save() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(lineWidth, forKey: defaultLineWidthKey)
        userDefaults.set(showImpulseOrigin, forKey: defaultShowImpulseOriginKey)
        userDefaults.set(defaultShowBlockKey, forKey: defaultShowBlockKey)


    }

    // TODO: retrieve preferences from shared preferences.
    mutating func retrieve() {
        let userDefaults = UserDefaults.standard
        lineWidth = userDefaults.integer(forKey: defaultLineWidthKey)
//        showImpulseOrigin = (userDefaults.object(forKey: defaultShowImpulseOriginKey) ?? false) as! Bool
//        showBlock = (userDefaults.object(forKey: defaultShowBlockKey) ?? false) as! Bool
    }
    
}
