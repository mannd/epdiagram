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
    var image: UIImage? // nil image is blank.
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
    // TODO: make diagram dirty when any marks are added or deleted.
    var isDirty: Bool {
        ladder.isDirty
    }

    var diagramData: DiagramData = DiagramData()
    struct DiagramData: Codable {
         var description: String = ""
         var ladder: Ladder = Ladder.defaultLadder()
        // creationDate, lastSavedDate?
    }

//    init(name: String?, image: UIImage, ladder: Ladder) {
//        self.name = name
//        self.image = image
//        self.ladder = ladder
//    }

    init(name: String?, image: UIImage?, diagramData: DiagramData) {
        self.name = name
        self.image = image
        self.diagramData = diagramData
    }

    // Will overwrite without asking.  Calling method should check if file exists and query for overwrite if appropriate.
    func save() throws {
        os_log("save() - Diagram", log: .action, type: .info)
        guard var name = name else { throw FileIOError.diagramIsUnnamed }
        if name.isBlank { throw FileIOError.diagramNameIsBlank }
        name = DiagramIO.cleanupFilename(name)
        let diagramDirURL = try DiagramIO.getDiagramDirURL(for: name)
        if let image = image {
            let imageData = image.pngData()
            let imageURL = diagramDirURL.appendingPathComponent(FileIO.imageFilename, isDirectory: false)
            try imageData?.write(to: imageURL)
        }
        let encoder = JSONEncoder()
        let diagramData = try encoder.encode(self.diagramData)
        let ladderURL = diagramDirURL.appendingPathComponent(FileIO.ladderFilename, isDirectory: false)
        FileManager.default.createFile(atPath: ladderURL.path, contents: diagramData, attributes: nil)
        ladder.isDirty = false
    }

    mutating func retrieve() throws {
        os_log("retrieve() - Diagram", log: .action, type: .info)
        guard let name = name else { throw FileIOError.diagramIsUnnamed }
        if name.isBlank { throw FileIOError.diagramNameIsBlank }
        let diagramDirURL = try DiagramIO.getDiagramDirURL(for: name)
        let imageURL = diagramDirURL.appendingPathComponent(FileIO.imageFilename, isDirectory: false)
        var image: UIImage? = nil
        if FileManager.default.fileExists(atPath: imageURL.path) {
            image = UIImage(contentsOfFile: imageURL.path)
        }
        let ladderURL = diagramDirURL.appendingPathComponent(FileIO.ladderFilename, isDirectory: false)
        let decoder = JSONDecoder()
        if let data = FileManager.default.contents(atPath: ladderURL.path) {
            let diagramData = try decoder.decode(DiagramData.self, from: data)
            self.image = image
            self.diagramData = diagramData
        }
        else {
            throw FileIOError.diagramDirectoryNotFound
        }
    }

    static func retrieve(name: String) throws -> Diagram {
        if name.isBlank { throw FileIOError.diagramNameIsBlank }
        let diagramDirURL = try DiagramIO.getDiagramDirURL(for: name)
        let imageURL = diagramDirURL.appendingPathComponent(FileIO.imageFilename, isDirectory: false)
        var image: UIImage? = nil
        if FileManager.default.fileExists(atPath: imageURL.path) {
            image = UIImage(contentsOfFile: imageURL.path)
        }
        let ladderURL = diagramDirURL.appendingPathComponent(FileIO.ladderFilename, isDirectory: false)
        let decoder = JSONDecoder()
        if let data = FileManager.default.contents(atPath: ladderURL.path) {
            let diagramData = try decoder.decode(DiagramData.self, from: data)
            let diagram = Diagram(name: name, image: image, diagramData: diagramData)
            return diagram
        }
        else {
            throw FileIOError.diagramDirectoryNotFound
        }
    }

    static func retrieveNoThrow(name: String) -> Diagram? {
        return try? retrieve(name: name)
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
        name = cleanedUpNewName
    }

    mutating func duplicate(duplicateName: String) throws {
        os_log("duplicate() - Diagram", log: .action, type: .info)
        guard let originalName = name else { throw FileIOError.diagramIsUnnamed }
        if duplicateName.isBlank { throw FileIOError.diagramNameIsBlank }
        let cleanedUpDuplicateName = DiagramIO.cleanupFilename(duplicateName)
        if originalName == cleanedUpDuplicateName { throw FileIOError.duplicateDiagramName }
        name = cleanedUpDuplicateName
        try save()
    }

    static func defaultDiagram(name: String? = nil) -> Diagram {
        let diagramData = DiagramData(description: "Normal ECG", ladder: Ladder.defaultLadder())
        return Diagram(name: name, image: UIImage(named: "SampleECG")!, diagramData: diagramData)
    }

    static func blankDiagram(name: String? = nil) -> Diagram {
        let diagramData = DiagramData(description: "Blank diagram", ladder: Ladder.defaultLadder())
        return Diagram(name: name, image: nil, diagramData: diagramData)
    }
}
