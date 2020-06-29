//
//  HamburgerViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 4/15/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

struct HamburgerViewModel {
    // Only set to true for testing.
    let showTestLayer = false

    func allLayers() -> [HamburgerLayer] {
        var array = [HamburgerLayer]()
        let cameraLayer = HamburgerLayer(withName: L("Take photo"), iconName: "camera", layer: .camera)
        array.append(cameraLayer)
        let selectPhotoLayer = HamburgerLayer(withName: L("Select image"), iconName: "photogallery", layer: .photoGallery)
        array.append(selectPhotoLayer)
        let lockImageLayer = HamburgerLayer(withName: L("Lock image"), iconName: "lock", layer: .lockImage, altName: L("Unlock image"), altIconName: "unlock")
        array.append(lockImageLayer)
        let openLayer = HamburgerLayer(withName: L("Open diagram"), iconName: "open", layer: .open)
        array.append(openLayer)
        let saveLayer = HamburgerLayer(withName: L("Save diagram"), iconName: "save", layer: .save)
        array.append(saveLayer)
        let renameLayer = HamburgerLayer(withName: L("Rename diagram"), iconName: "write", layer: .rename)
        array.append(renameLayer)
        let duplicateLayer = HamburgerLayer(withName: L("Duplicate diagram"), iconName: "duplicate", layer: .duplicate)
        array.append(duplicateLayer)
        let saveImageLayer = HamburgerLayer(withName: L("Snapshot diagram"), iconName: "save_image", layer: .snapshot)
        array.append(saveImageLayer)
        let sampleLayer = HamburgerLayer(withName: L("Sample diagrams"), iconName: "ecg", layer: .sample)
        array.append(sampleLayer)
        let lockLadderLayer = HamburgerLayer(withName: L("Lock ladder"), iconName: "lock", layer: .lockLadder, altName: L("Unlock ladder"), altIconName: "unlock")
        array.append(lockLadderLayer)
        let templatesLayer = HamburgerLayer(withName: L("Ladder editor"), iconName: "templates", layer: .templates)
        array.append(templatesLayer)
        let preferencesLayer = HamburgerLayer(withName: L("Preferences"), iconName: "preferences", layer: .preferences)
        array.append(preferencesLayer)
        let helpLayer = HamburgerLayer(withName: L("Help"), iconName: "help", layer: .help)
        array.append(helpLayer)
        let aboutLayer = HamburgerLayer(withName: L("About EP Diagram"), iconName: "about", layer: .about)
        array.append(aboutLayer)
        // Never show test layer with release build configuration.
        #if DEBUG
        if showTestLayer {
            let testLayer = HamburgerLayer(withName: "TEST", iconName: "test", layer: .test)
            array.append(testLayer)
        }
        #endif


        return array
    }

}
