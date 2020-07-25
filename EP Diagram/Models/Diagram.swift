//
//  Diagram.swift
//  EP Diagram
//
//  Created by David Mann on 6/3/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log



struct Diagram {
    var name: String?
    var image: UIImage
    var description: String {
        get { diagramData.description }
        set(newValue) { diagramData.description = newValue }
    }
    var ladder: Ladder {
        get { diagramData.ladder }
        set(newValue) { diagramData.ladder = newValue }
    }
    // Future use?
//    var creationDate: Date?
//    var lastSavedDate: Date?
    // A diagram does not get a name until it is saved.
    var isSaved: Bool {
        !name.isBlank
    }

    private var diagramData: DiagramData = DiagramData()
    private struct DiagramData: Codable {
         var description: String = ""
         var ladder: Ladder = Ladder.defaultLadder()
        // creationDate, lastSavedDate?
    }

    init(name: String?, image: UIImage, ladder: Ladder) {
        self.name = name
        self.image = image
        self.ladder = ladder
    }

    // TODO: validate legal file name
    func save() throws {
        os_log("save() - Diagram", log: .action, type: .info)
        guard var name = name else { throw FileIOError.diagramIsUnnamed }
        if name.isBlank { throw FileIOError.diagramNameIsBlank }
        name = DiagramIO.cleanupFilename(name)
        let diagramDirURL = try DiagramIO.getDiagramDirURL(for: name)
        let imageData = image.pngData()
        let imageURL = diagramDirURL.appendingPathComponent(FileIO.imageFilename, isDirectory: false)
        try imageData?.write(to: imageURL)
        let encoder = JSONEncoder()
        let diagramData = try encoder.encode(self.diagramData)
        let ladderURL = diagramDirURL.appendingPathComponent(FileIO.ladderFilename, isDirectory: false)
        FileManager.default.createFile(atPath: ladderURL.path, contents: diagramData, attributes: nil)
        ladder.isDirty = false
    }

    // Non-throwing version of save().
    func saveNoThrow() -> Error? {
        os_log("saveNoThrow() - Diagram", log: .action, type: .info)
        do {
            try save()
            return nil
        } catch {
            return error
        }
    }

    mutating func retrieve() throws {
        os_log("retrieve() - Diagram", log: .action, type: .info)
        guard let name = name else { throw FileIOError.diagramIsUnnamed }
        if name.isBlank { throw FileIOError.diagramNameIsBlank }
        let diagramDirURL = try DiagramIO.getDiagramDirURL(for: name)
        let imageURL = diagramDirURL.appendingPathComponent(FileIO.imageFilename, isDirectory: false)
        let image = UIImage(contentsOfFile: imageURL.path)
        let ladderURL = diagramDirURL.appendingPathComponent(FileIO.ladderFilename, isDirectory: false)
        let decoder = JSONDecoder()
        if let data = FileManager.default.contents(atPath: ladderURL.path), let image = image {
            let diagramData = try decoder.decode(DiagramData.self, from: data)
            self.image = image
            self.diagramData = diagramData
        }
        else {
            throw FileIOError.diagramDirectoryNotFound
        }
    }

    mutating func rename(newName: String) throws {
        os_log("rename() - Diagram", log: .action, type: .info)
        guard let oldName = name else { throw FileIOError.diagramIsUnnamed }
        if newName.isBlank { throw FileIOError.diagramNameIsBlank }
        let cleanedUpNewName = DiagramIO.cleanupFilename(newName)
        if oldName == cleanedUpNewName { throw FileIOError.duplicateDiagramName }
        let diagramDirURL = try DiagramIO.getDiagramDirURL(for: oldName)
        let diagramDirURLPath = diagramDirURL.path
        P("\(diagramDirURLPath)T")
        let epDiagramDirURL = try DiagramIO.getEPDiagramsDirURL()
        let newDiagramURLPath = epDiagramDirURL.appendingPathComponent(cleanedUpNewName, isDirectory: true).path
        try FileManager.default.moveItem(atPath: diagramDirURLPath, toPath: newDiagramURLPath)
        self.name = cleanedUpNewName
    }

    mutating func renameNoThrow(newName: String) -> Error? {
        os_log("renameNoThrow() - Diagram", log: .action, type: .info)
        do {
            try rename(newName: newName)
            return nil
        } catch {
            return error
        }
    }

    mutating func duplicate(duplicateName: String) throws {
        os_log("duplicate() - Diagram", log: .action, type: .info)
        guard let originalName = name else { throw FileIOError.diagramIsUnnamed }
        if duplicateName.isBlank { throw FileIOError.diagramNameIsBlank }
        let cleanedUpDuplicateName = DiagramIO.cleanupFilename(duplicateName)
        if originalName == cleanedUpDuplicateName { throw FileIOError.duplicateDiagramName }
        name = cleanedUpDuplicateName
        if let error = saveNoThrow() {
            // Don't rename if save doesn't work
            name = originalName
            throw error
        }
    }

    mutating func duplicateNoThrow(duplicateName: String) -> Error? {
        os_log("duplicateNoThrow() - Diagram", log: .action, type: .info)
        do {
            try duplicate(duplicateName: duplicateName)
            return nil
        } catch {
            return error
        }
    }

    static func getDefaultDiagram() -> Diagram {
        return Diagram(name: nil, image: UIImage(named: "SampleECG")!, ladder: Ladder.defaultLadder())
    }
}
