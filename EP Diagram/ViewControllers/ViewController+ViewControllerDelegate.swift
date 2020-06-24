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
}

extension ViewController: ViewControllerDelegate {
    func selectLadderTemplate(ladderTemplate: LadderTemplate?) {
        os_log("selecteLadderTemplate - ViewController", log: OSLog.action, type: .info)
        if let ladderTemplate = ladderTemplate {
            let ladder = Ladder(template: ladderTemplate)
            ladderView.ladder = ladder
            setViewsNeedDisplay()
        }
    }

    func selectDiagram(diagramName: String?) {
        guard let diagramName = diagramName else { return }
        P("diagram name = \(diagramName)")
        do {
            guard let documentDirURL = FileIO.getURL(for: .documents) else {
                os_log("File error: user document directory not found!", log: .errors, type: .error)
                Common.showMessage(viewController: self, title: L("File Error"), message: "User document directory not found!")
                throw FileIO.FileIOError.documentDirectoryNotFound
            }
            let diagramDirURL = documentDirURL.appendingPathComponent(FileIO.epdiagramDir, isDirectory: true)
            if !FileManager.default.fileExists(atPath: diagramDirURL.path) {
                throw FileIO.FileIOError.diagramDirectoryNotFound
            }
            let ultimateDirURL = diagramDirURL.appendingPathComponent(diagramName, isDirectory: true)
            if !FileManager.default.fileExists(atPath: ultimateDirURL.path) {
                throw FileIO.FileIOError.diagramDirectoryNotFound
            }
            // TODO: check if image and json files exist
            let imageURL = ultimateDirURL.appendingPathComponent("image.png", isDirectory: false)
            P("imageURL.path = \(imageURL.path)")
            let image = UIImage(contentsOfFile: imageURL.path)
            self.imageView.image = image
            self.setViewsNeedDisplay()
            let ladderURL = ultimateDirURL.appendingPathComponent("ladder.json", isDirectory: false)
            let decoder = JSONDecoder()
            if let data = FileManager.default.contents(atPath: ladderURL.path) {
                if let ladder = try? decoder.decode(Ladder.self, from: data) {

                    self.imageView.image = image
                    self.ladderView.ladder = ladder
                    self.setViewsNeedDisplay()
                }
            }
        } catch {
            os_log("Error: %s", error.localizedDescription)
        }
    }

    func deleteDiagram(diagramName: String) {
        os_log("deleteDiagram %s", log: .action, type: .info, diagramName)
        // actually delete diagram files here
        do {
            let diagramDirURL = try getDiagramDirURL(for: diagramName)
            //P("\(epDiagramsDirURL.path)")
            let diagramDirContents = try FileManager.default.contentsOfDirectory(atPath: diagramDirURL.path)
            P("diagramDirContents = \(diagramDirContents)")
            for path in diagramDirContents {
                let pathURL = diagramDirURL.appendingPathComponent(path, isDirectory: false)
                try FileManager.default.removeItem(atPath: pathURL.path)
            }
            try FileManager.default.removeItem(atPath: diagramDirURL.path)
        } catch {
            os_log("Could not delete diagram %s, error: %s", log: .action, type: .error, diagramName, error.localizedDescription)
        }
    }
}
