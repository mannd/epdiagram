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
    func selectDiagram(diagramName: String?)
    func deleteDiagram(diagramName: String)
    func savePreferences(preferences: Preferences)
    func saveTemplates(_ templates: [LadderTemplate])
}

extension ViewController: ViewControllerDelegate {
    func selectLadderTemplate(ladderTemplate: LadderTemplate?) {
        os_log("selecteLadderTemplate - ViewController", log: OSLog.action, type: .info)
        if let ladderTemplate = ladderTemplate {
            let ladder = Ladder(template: ladderTemplate)
            diagram?.name = nil
            ladderView.ladder = ladder
            setViewsNeedDisplay()
        }
    }

    func selectDiagram(diagramName: String?) {
        guard let diagramName = diagramName else { return }
        P("diagram name = \(diagramName)")
        do {
            let diagramDirURL = try getDiagramDirURL(for: diagramName)
            let imageURL = diagramDirURL.appendingPathComponent(FileIO.imageFilename, isDirectory: false)
            let image = UIImage(contentsOfFile: imageURL.path)
            let ladderURL = diagramDirURL.appendingPathComponent(FileIO.ladderFilename, isDirectory: false)
            let decoder = JSONDecoder()
            if let data = FileManager.default.contents(atPath: ladderURL.path), let image = image {
                if let ladder = try? decoder.decode(Ladder.self, from: data) {
                    self.diagram = Diagram(name: diagramName, image: image, ladder: ladder)
                    self.imageView.image = image
                    self.ladderView.ladder = ladder
                    self.setViewsNeedDisplay()
                }
            }
        } catch {
            os_log("Error: %s", error.localizedDescription)
            Common.ShowFileError(viewController: self, error: error)
        }
    }

    func deleteDiagram(diagramName: String) {
        os_log("deleteDiagram %s", log: .action, type: .info, diagramName)
        // actually delete diagram files here
        do {
            let diagramDirURL = try getDiagramDirURL(for: diagramName)
            let diagramDirContents = try FileManager.default.contentsOfDirectory(atPath: diagramDirURL.path)
            for path in diagramDirContents {
                let pathURL = diagramDirURL.appendingPathComponent(path, isDirectory: false)
                try FileManager.default.removeItem(atPath: pathURL.path)
            }
            try FileManager.default.removeItem(atPath: diagramDirURL.path)
        } catch {
            os_log("Could not delete diagram %s, error: %s", log: .action, type: .error, diagramName, error.localizedDescription)
            Common.ShowFileError(viewController: self, error: error)
        }
    }

    func savePreferences(preferences: Preferences) {
        os_log("savePreferences()", log: .action, type: .info)
        self.preferences = preferences
        self.preferences.save()
        ladderView.lineWidth = CGFloat(preferences.lineWidth)
        ladderView.showBlock = preferences.showBlock
        ladderView.showImpulseOrigin = preferences.showImpulseOrigin
        setViewsNeedDisplay()
    }

    func saveTemplates(_ templates: [LadderTemplate]) {
        os_log("saveTemplates()", log: .action, type: .info)
        do {
            try FileIO.store(templates, to: .documents, withFileName: FileIO.userTemplateFile)
        } catch {
            os_log("File error: %s", log: .errors, type: .error, error.localizedDescription)
            Common.ShowFileError(viewController: self, error: error)
        }
    }
}
