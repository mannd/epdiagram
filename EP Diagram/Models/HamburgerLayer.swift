//
//  HamburgerLayer.swift
//  EP Diagram
//
//  Created by David Mann on 4/15/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

enum Layer {
    case camera
    case photoGallery
    case open
    case save
    case rename
    case duplicate
    case sample
    case templates
    case lockImage
    case lockLadder
    case preferences
    case help
    case about
}

struct HamburgerLayer {
    var name: String?
    var iconName: String?
    var layer: Layer?
    var altName: String?
    var altIconName: String?

    init(withName name: String, iconName: String, layer: Layer) {
        self.name = name
        self.iconName = iconName
        self.layer = layer
        self.altName = nil
        self.altIconName = nil
    }

    init(withName name: String, iconName: String, layer: Layer, altName: String, altIconName: String) {
        self.name = name
        self.iconName = iconName
        self.layer = layer
        self.altName = altName
        self.altIconName = altIconName
    }
}
