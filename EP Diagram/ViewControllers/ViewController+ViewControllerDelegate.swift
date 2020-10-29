//
//  ViewController+ViewControllerDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 5/31/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

protocol ViewControllerDelegate: class {
    func selectLadderTemplate(ladderTemplate: LadderTemplate?)
    func selectDiagram(named name: String?)
    func deleteDiagram(named name: String)
//    func savePreferences(_ preferences: Preferences)
    func saveTemplates(_ templates: [LadderTemplate])
    func selectSampleDiagram(_ diagram: Diagram?)
    func setViewsNeedDisplay()
    func updatePreferences()
}

extension ViewController: ViewControllerDelegate {
    func selectLadderTemplate(ladderTemplate: LadderTemplate?) {
        os_log("selecteLadderTemplate - ViewController", log: OSLog.action, type: .info)
        P("ladder is dirty = \(ladderView.ladderIsDirty)")

        if let ladderTemplate = ladderTemplate {
            let ladder = Ladder(template: ladderTemplate)
            // Reuse image if there is one.
            setDiagramImage(imageView.image)
            diagram.ladder = ladder
            ladderView.ladder = ladder
            setViewsNeedDisplay()
        }
    }

    func selectDiagram(named name: String?) {
        guard let diagramName = name else { return }
        P("diagram name = \(diagramName)")
        do {
            diagram = try Diagram.retrieve(name: diagramName)
            self.imageView.image = diagram.image
            self.ladderView.ladder = diagram.ladder
            self.setTitle()
            DiagramIO.saveLastDiagram(name: diagram.name)
            self.setViewsNeedDisplay()
        } catch {
            os_log("Error: %s", log: .errors, type: .error, error.localizedDescription)
            Common.showFileError(viewController: self, error: error)
        }
    }

    func deleteDiagram(named name: String) {
        os_log("deleteDiagram %s", log: .action, type: .info, name)
        // actually delete diagram files here
        do {
            let diagramDirURL = try DiagramIO.getDiagramDirURL(for: name)
            let diagramDirContents = try FileManager.default.contentsOfDirectory(atPath: diagramDirURL.path)
            for path in diagramDirContents {
                let pathURL = diagramDirURL.appendingPathComponent(path, isDirectory: false)
                try FileManager.default.removeItem(atPath: pathURL.path)
            }
            try FileManager.default.removeItem(atPath: diagramDirURL.path)
        } catch {
            os_log("Could not delete diagram %s, error: %s", log: .action, type: .error, name, error.localizedDescription)
            Common.showFileError(viewController: self, error: error)
        }
    }

//    func savePreferences(_ preferences: Preferences) {
//        os_log("savePreferences()", log: .action, type: .info)
//        self.preferences = preferences
//        self.preferences.save()
//        ladderView.lineWidth = CGFloat(preferences.lineWidth)
//        ladderView.showBlock = preferences.showBlock
//        ladderView.showImpulseOrigin = preferences.showImpulseOrigin
//        ladderView.showIntervals = preferences.showIntervals
//        setViewsNeedDisplay()
//    }

    @objc
    func updatePreferences() {
        os_log("updatePreferences()", log: .action, type: .info)
        ladderView.lineWidth = CGFloat(UserDefaults.standard.double(forKey: Preferences.defaultLineWidthKey))
        ladderView.showBlock = UserDefaults.standard.bool(forKey: Preferences.defaultShowBlockKey)
        ladderView.showImpulseOrigin = UserDefaults.standard.bool(forKey: Preferences.defaultShowImpulseOriginKey)
        ladderView.showIntervals = UserDefaults.standard.bool(forKey: Preferences.defaultShowIntervalsKey)
        setViewsNeedDisplay()
    }

    @objc
    func enterBackground() {
//        os_log("enterBackground()", log: .lifeCycle, type: .info)
//        // save ladder to User Activity here and cache image.
//        // Remember image doesn't change, so only cache once.
//        if let id = view.window?.windowScene?.session.persistentIdentifier {
//            do {
//                if var url = FileIO.getURL(for: .cache) {
//                    os_log("cach path = %s", url.path)
//                    url = url.appendingPathComponent(id)
//                    if !FileManager.default.fileExists(atPath: url.path) {
//                        try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
//                    }
//                    try diagram.save(name: id, url: url)
//                    diagram.image = nil
//                }
//            } catch {
//                os_log("Error saving temp diagram file: %s", log: .errors, type: .error, error.localizedDescription)
//            }
//        }
    }

    @objc
    func enterForeground() {
//        os_log("enterForground()", log: .lifeCycle, type: .info)
//        // FIXME: id is nil here?? why??
//        if let id = view.window?.windowScene?.session.persistentIdentifier {
//            do {
//                if var url = FileIO.getURL(for: .cache) {
//                    url = url.appendingPathComponent(id)
//                    try diagram = Diagram.retrieve(name: id, url: url)
//                    url = url.appendingPathComponent(id)
//                    if FileManager.default.fileExists(atPath: url.path) {
//                        do {
//                            try FileManager.default.removeItem(at: url)
//                        } catch {
//                            fatalError(error.localizedDescription)
//                        }
//                    }
//                }
//            } catch {
//                os_log("Error retrieving temp diagram file: %s", log: .errors, type: .error, error.localizedDescription)
//            }
//        }
    }

    @objc
    func willConnect() {
        os_log("willConnect()", log: .lifeCycle, type: .info)
    }

    @objc
    func didDisconnect() {
        os_log("didDisconnect()", log: .lifeCycle, type: .info)

    }

    

    func saveTemplates(_ templates: [LadderTemplate]) {
        os_log("saveTemplates()", log: .action, type: .info)
        do {
            try FileIO.store(templates, to: .documents, withFileName: FileIO.userTemplateFile)
        } catch {
            os_log("File error: %s", log: .errors, type: .error, error.localizedDescription)
            Common.showFileError(viewController: self, error: error)
        }
    }

    func selectSampleDiagram(_ diagram: Diagram?) {
        os_log("selectSampleDiagram()", log: .action, type: .info)
        guard let diagram = diagram else { return }
        self.diagram = diagram
        self.imageView.image = diagram.image
        self.ladderView.ladder = diagram.ladder
        setTitle()
        setViewsNeedDisplay()
    }

    func setViewsNeedDisplay() {
        cursorView.setNeedsDisplay()
        ladderView.setNeedsDisplay()
    }

}
