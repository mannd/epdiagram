//
//  Diagram.swift
//  EP Diagram
//
//  Created by David Mann on 6/3/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

private enum Keys: String, CustomStringConvertible {
    case name = "diagramName"
    case description = "diagramDescription"
    case image = "diagramImage"
    case ladder = "diagramLadder"

    var description: String {
        return self.rawValue
    }
}

class Diagram: NSCoding {

    var name: String?
    var image: UIImage? // nil image is blank.
    var description: String

    var ladder: Ladder
    
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

    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: Keys.name.description)
        coder.encode(description, forKey: Keys.description.description)
        coder.encode(image, forKey: Keys.image.description)
        coder.encode(ladder, forKey: Keys.ladder.description)
    }

    required init?(coder: NSCoder) {
        name = coder.decodeObject(forKey: Keys.name.description) as? String
        description = coder.decodeObject(forKey: Keys.description.description) as? String ?? ""
        if let data = coder.decodeObject(forKey: Keys.image.description) as? Data {
            image = UIImage(data: data)
        }
        if let ladder = coder.decodeObject(forKey: Keys.ladder.description) as? Ladder {
            self.ladder = ladder
        } else {
            self.ladder = Ladder.defaultLadder()
        }
    }


//    var diagramData: DiagramData = DiagramData()
//    struct DiagramData: Codable {
//        var name: String?
//        var description: String = ""
//        var ladder: Ladder = Ladder.defaultLadder()
//        // creationDate, lastSavedDate?
//    }

    init(name: String?, description: String, image: UIImage?, ladder: Ladder) {
        self.name = name
        self.description = description
        self.image = image
        self.ladder = ladder
    }

//    init(name: String?, image: UIImage?, diagramData: DiagramData) {
//        self.name = name
//        self.image = image
//        self.diagramData = diagramData
//    }

    // init a Diagram with default ladder.
//    init(name: String?, image: UIImage?, description: String = "") {
//        let diagramData = DiagramData(name: name, description: description, ladder: Ladder.defaultLadder())
//        self = Diagram(name: name, image: image, diagramData: diagramData)
//    }

//    // Will overwrite without asking.  Calling method should check if file exists and query for overwrite if appropriate.
//    func save() throws {
//        os_log("save() - Diagram", log: .action, type: .info)
//        guard var name = name else { throw FileIOError.diagramIsUnnamed }
//        if name.isBlank { throw FileIOError.diagramNameIsBlank }
//        name = DiagramIO.cleanupFilename(name)
//        try save(fileName: name)
//    }
//
//    func save(fileName: String) throws {
//        let url = try DiagramIO.getDiagramDirURL(for: fileName)
//        try save(fileName: fileName, url: url)
//    }
//
//    func save(fileName: String, url: URL) throws {
//        if let image = image {
//            let imageData = image.pngData()
//            let imageURL = url.appendingPathComponent(FileIO.imageFilename, isDirectory: false)
//            try imageData?.write(to: imageURL)
//        }
//        let encoder = JSONEncoder()
//        let diagramData = try encoder.encode(self.diagramData)
//        let ladderURL = url.appendingPathComponent(FileIO.ladderFilename, isDirectory: false)
//        FileManager.default.createFile(atPath: ladderURL.path, contents: diagramData, attributes: nil)
//    }
//
//    mutating func retrieve() throws {
//        os_log("retrieve() - Diagram", log: .action, type: .info)
//        guard let name = name else { throw FileIOError.diagramIsUnnamed }
//        if name.isBlank { throw FileIOError.diagramNameIsBlank }
//        self = try Diagram.retrieve(fileName: name)
//    }
//
//    static func retrieve(fileName: String) throws -> Diagram {
//        if fileName.isBlank { throw FileIOError.diagramNameIsBlank }
//        let diagramDirURL = try DiagramIO.getDiagramDirURL(for: fileName)
//        return try retrieve(fileName: fileName, url: diagramDirURL)
//    }
//
//    static func retrieve(fileName: String, url: URL) throws -> Diagram {
//        let imageURL = url.appendingPathComponent(FileIO.imageFilename, isDirectory: false)
//        var image: UIImage? = nil
//        if FileManager.default.fileExists(atPath: imageURL.path) {
//            image = UIImage(contentsOfFile: imageURL.path)
//        }
//        let ladderURL = url.appendingPathComponent(FileIO.ladderFilename, isDirectory: false)
//        let decoder = JSONDecoder()
//        if let data = FileManager.default.contents(atPath: ladderURL.path) {
//            let diagramData = try decoder.decode(DiagramData.self, from: data)
//            let diagram = Diagram(name: fileName, image: image, diagramData: diagramData)
//            return diagram
//        }
//        else {
//            throw FileIOError.diagramDirectoryNotFound
//        }
//    }
//
//    static func retrieveNoThrow(name: String) -> Diagram? {
//        return try? retrieve(fileName: name)
//    }
//
//    mutating func rename(newName: String) throws {
//        os_log("rename() - Diagram", log: .action, type: .info)
//        guard let oldName = name else { throw FileIOError.diagramIsUnnamed }
//        if newName.isBlank { throw FileIOError.diagramNameIsBlank }
//        let cleanedUpNewName = DiagramIO.cleanupFilename(newName)
//        if oldName == cleanedUpNewName { throw FileIOError.duplicateDiagramName }
//        let diagramDirURL = try DiagramIO.getDiagramDirURL(for: oldName)
//        let diagramDirURLPath = diagramDirURL.path
//        P("\(diagramDirURLPath)T")
//        let epDiagramDirURL = try DiagramIO.getEPDiagramsDirURL()
//        let newDiagramURLPath = epDiagramDirURL.appendingPathComponent(cleanedUpNewName, isDirectory: true).path
//        try FileManager.default.moveItem(atPath: diagramDirURLPath, toPath: newDiagramURLPath)
//        name = cleanedUpNewName
//    }
//
//    mutating func duplicate(duplicateName: String) throws {
//        os_log("duplicate() - Diagram", log: .action, type: .info)
//        guard let originalName = name else { throw FileIOError.diagramIsUnnamed }
//        if duplicateName.isBlank { throw FileIOError.diagramNameIsBlank }
//        let cleanedUpDuplicateName = DiagramIO.cleanupFilename(duplicateName)
//        if originalName == cleanedUpDuplicateName { throw FileIOError.duplicateDiagramName }
//        name = cleanedUpDuplicateName
//        try save()
//    }
//
    static func defaultDiagram(name: String? = nil) -> Diagram {
        return Diagram(name: name, description: "Normal ECG", image: UIImage(named: "SampleECG")!, ladder: Ladder.defaultLadder())
    }


    static func blankDiagram(name: String? = nil) -> Diagram {
        let diagram = Diagram(name: name, description: "Blank diagram", image: nil, ladder: Ladder.defaultLadder())
//        diagram.ladder.zone = Zone(regions: [diagram.ladder.regions[0], diagram.ladder.regions[1]], start: 100, end: 250)
        return diagram
    }


}
