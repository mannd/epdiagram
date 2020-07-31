//
//  HamburgerViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 4/15/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

struct HamburgerViewModel {
    // Only set to true for testing.  Note it will be ignored anyway for release version.
    let showTestLayer = true
    var diagramSaved = false

    func allLayers() -> [HamburgerLayer] {
        var array = [HamburgerLayer]()
        let takePhotoLayer = HamburgerLayer(withName: L("Take photo"), iconName: "camera", layer: .takePhoto)
        array.append(takePhotoLayer)
        let selectImageLayer = HamburgerLayer(withName: L("Select image"), iconName: "photogallery", layer: .selectImage)
        array.append(selectImageLayer)
        let lockImageLayer = HamburgerLayer(withName: L("Lock image"), iconName: "lock", layer: .lockImage, altName: L("Unlock image"), altIconName: "unlock")
        array.append(lockImageLayer)
        let newDiagramlayer = HamburgerLayer(withName: L("New diagram"), iconName: "plus_square", layer: .newDiagram)
        array.append(newDiagramlayer)
        let selectDiagramLayer = HamburgerLayer(withName: L("Select diagram"), iconName: "open", layer: .openDiagram)
        array.append(selectDiagramLayer)
        let saveDiagramLayer = HamburgerLayer(withName: L("Save diagram"), iconName: "save", layer: .saveDiagram)
        array.append(saveDiagramLayer)
        var renameDiagramLayer = HamburgerLayer(withName: L("Rename diagram"), iconName: "write", layer: .renameDiagram)
        renameDiagramLayer.isEnabled = diagramSaved
        array.append(renameDiagramLayer)
        var duplicateDiagramLayer = HamburgerLayer(withName: L("Duplicate diagram"), iconName: "duplicate", layer: .duplicateDiagram)
        duplicateDiagramLayer.isEnabled = diagramSaved
        array.append(duplicateDiagramLayer)
        let getInfoLayer = HamburgerLayer(withName: L("Diagram info"), iconName: "diagramInfo", layer: .getInfo)
        array.append(getInfoLayer)
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
