//
//  HamburgerLayer.swift
//  EP Diagram
//
//  Created by David Mann on 4/15/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

enum Layer {
    case takePhoto
    case selectImage
    case selectLadder
    case renameDiagram
    case getInfo
    case snapshot
    case sample
    case templates
    case lockImage
    case lockLadder
    case preferences
    case help
    case about
    case test
}

struct HamburgerLayer {
    var name: String?
    var iconName: String?
    var icon: UIImage?
    var layer: Layer?
    var altName: String?
    var altIconName: String?
    var altIcon: UIImage?
    var isEnabled: Bool = true

    init(withName name: String, icon: UIImage?, layer: Layer) {
        self.name = name
        self.icon = icon
        self.layer = layer
        self.altName = nil
        self.altIcon = nil
    }

    init(withName name: String, icon: UIImage?, layer: Layer, altName: String, altIcon: UIImage?) {
        self.name = name
        self.icon = icon
        self.layer = layer
        self.altName = altName
        self.altIcon = altIcon
    }
}
