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
        let takePhotoLayer = HamburgerLayer(withName: L("Take photo"), icon: UIImage(systemName: "camera"), layer: .takePhoto)
        array.append(takePhotoLayer)
        let selectImageLayer = HamburgerLayer(withName: L("Select image"), icon: UIImage(systemName: "photo"), layer: .selectImage)
        array.append(selectImageLayer)
        // FIXME: need ladder svg
        let selectLadderLayer = HamburgerLayer(withName: L("Select ladder"), icon: UIImage(named: "ladder"), layer: .selectLadder)
        array.append(selectLadderLayer)
        let newDiagramlayer = HamburgerLayer(withName: L("New diagram"), icon: UIImage(systemName: "plus.app"), layer: .newDiagram)
        array.append(newDiagramlayer)
        let selectDiagramLayer = HamburgerLayer(withName: L("Select diagram"), icon: UIImage(systemName: "checkmark.circle"), layer: .openDiagram)
        array.append(selectDiagramLayer)
        let saveDiagramLayer = HamburgerLayer(withName: L("Save diagram"), icon: UIImage(systemName: "square.and.arrow.down"), layer: .saveDiagram)
        array.append(saveDiagramLayer)
        var renameDiagramLayer = HamburgerLayer(withName: L("Rename diagram"), icon: UIImage(systemName: "square.and.pencil"), layer: .renameDiagram)
        renameDiagramLayer.isEnabled = diagramSaved
        array.append(renameDiagramLayer)
        var duplicateDiagramLayer = HamburgerLayer(withName: L("Duplicate diagram"), icon: UIImage(systemName: "plus.square.on.square"), layer: .duplicateDiagram)
        duplicateDiagramLayer.isEnabled = diagramSaved
        array.append(duplicateDiagramLayer)
        let getInfoLayer = HamburgerLayer(withName: L("Diagram info"), icon: UIImage(systemName: "questionmark.square"), layer: .getInfo)
        array.append(getInfoLayer)
        let saveImageLayer = HamburgerLayer(withName: L("Snapshot diagram"), icon: UIImage(systemName: "photo.on.rectangle"), layer: .snapshot)
        array.append(saveImageLayer)
        let sampleLayer = HamburgerLayer(withName: L("Sample diagrams"), icon: UIImage(systemName: "waveform.path.ecg"), layer: .sample)
        array.append(sampleLayer)
        let lockImageLayer = HamburgerLayer(withName: L("Lock image"), icon: UIImage(systemName: "lock"), layer: .lockImage, altName: L("Unlock image"), altIcon: UIImage(systemName: "lock.open"))
        array.append(lockImageLayer)
        let lockLadderLayer = HamburgerLayer(withName: L("Lock ladder"), icon: UIImage(systemName: "lock"), layer: .lockLadder, altName: L("Unlock ladder"), altIcon: UIImage(systemName: "lock.open"))
        array.append(lockLadderLayer)
        let templatesLayer = HamburgerLayer(withName: L("Ladder editor"), icon: UIImage(systemName: "list.dash"), layer: .templates)
        array.append(templatesLayer)
        let preferencesLayer = HamburgerLayer(withName: L("Preferences"), icon: UIImage(systemName: "gear"), layer: .preferences)
        array.append(preferencesLayer)
        let helpLayer = HamburgerLayer(withName: L("Help"), icon: UIImage(systemName: "questionmark.circle"), layer: .help)
        array.append(helpLayer)
        let aboutLayer = HamburgerLayer(withName: L("About EP Diagram"), icon: UIImage(systemName: "info.circle"), layer: .about)
        array.append(aboutLayer)
        // Never show test layer with release build configuration.
        #if DEBUG
        if showTestLayer {
            let testLayer = HamburgerLayer(withName: "TEST", icon: UIImage(named: "test"), layer: .test)
            array.append(testLayer)
        }
        #endif


        return array
    }

}
