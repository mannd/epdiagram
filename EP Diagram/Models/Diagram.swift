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
    var description: String {
        get {
            ladder.description
        }
        set(newValue) {
            ladder.description = newValue
        }
    }
    var image: UIImage
    var ladder: Ladder
    // Future use?
    var creationDate: Date?
    var lastSavedDate: Date?
    // A diagram does not get a name until it is saved.
    var isSaved: Bool {
        !name.isBlank
    }

    func save() throws {
        os_log("save() - Diagram", log: .action, type: .info)
        guard let name = name else { throw FileIOError.diagramIsUnnamed }
        let diagramDirURL = try DiagramIO.getDiagramDirURL(for: name)
        let imageData = image.pngData()
        let imageURL = diagramDirURL.appendingPathComponent(FileIO.imageFilename, isDirectory: false)
        try imageData?.write(to: imageURL)
        let encoder = JSONEncoder()
        let ladderData = try encoder.encode(ladder)
        let ladderURL = diagramDirURL.appendingPathComponent(FileIO.ladderFilename, isDirectory: false)
        FileManager.default.createFile(atPath: ladderURL.path, contents: ladderData, attributes: nil)
        ladder.isDirty = false
    }

    mutating func retrieve() throws {
        os_log("retrieve() - Diagram", log: .action, type: .info)
        guard let name = name else { throw FileIOError.diagramIsUnnamed }
        let diagramDirURL = try DiagramIO.getDiagramDirURL(for: name)
        let imageURL = diagramDirURL.appendingPathComponent(FileIO.imageFilename, isDirectory: false)
        let image = UIImage(contentsOfFile: imageURL.path)
        let ladderURL = diagramDirURL.appendingPathComponent(FileIO.ladderFilename, isDirectory: false)
        let decoder = JSONDecoder()
        if let data = FileManager.default.contents(atPath: ladderURL.path), let image = image {
            let ladder = try decoder.decode(Ladder.self, from: data)
            self.image = image
            self.ladder = ladder
        }
        else {
            throw FileIOError.diagramDirectoryNotFound
        }
    }

    static func getDefaultDiagram() -> Diagram {
        return Diagram(name: nil, image: UIImage(named: "SampleECG")!, ladder: Ladder.defaultLadder())
    }
}
