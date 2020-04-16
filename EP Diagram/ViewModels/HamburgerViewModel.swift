//
//  HamburgerViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 4/15/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

struct HamburgerViewModel {
    func allLayers() -> [HamburgerLayer] {
        var array: Array<HamburgerLayer> = []
        let cameraLayer = HamburgerLayer(withName: L("Take photo"), iconName: "camera", layer: .camera)
        array.append(cameraLayer)
        let selectPhotoLayer = HamburgerLayer(withName: L("Select image"), iconName: "photos", layer: .photoGallery)
        array.append(selectPhotoLayer)
        let lockImageLayer = HamburgerLayer(withName: L("Lock image"), iconName: "lock", layer: .lock)
        array.append(lockImageLayer)
        let preferencesLayer = HamburgerLayer(withName: L("Preferences"), iconName: "preferences", layer: .preferences)
        array.append(preferencesLayer)
        let openLayer = HamburgerLayer(withName: L("Open diagram"), iconName: "open", layer: .open)
        array.append(openLayer)
        let saveLayer = HamburgerLayer(withName: L("Save diagram"), iconName: "save", layer: .save)
        array.append(saveLayer)
        let helpLayer = HamburgerLayer(withName: L("Help"), iconName: "help", layer: .help)
        array.append(helpLayer)
        let aboutLayer = HamburgerLayer(withName: L("About EP Diagram"), iconName: "about", layer: .about)
        array.append(aboutLayer)

        return array
    }

}
