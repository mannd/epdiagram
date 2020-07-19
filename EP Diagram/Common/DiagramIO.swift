//
//  DiagramIO.swift
//  EP Diagram
//
//  Created by David Mann on 7/14/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import Foundation

class DiagramIO {
    static func getEPDiagramsDirURL() throws -> URL {
        guard let documentDirURL = FileIO.getURL(for: .documents) else {
            throw FileIOError.documentDirectoryNotFound
        }
        P("documentDirURL = \(documentDirURL)")
        let epDiagramsDirURL = documentDirURL.appendingPathComponent(FileIO.epDiagramDir, isDirectory: true)
        if !FileManager.default.fileExists(atPath: epDiagramsDirURL.path) {
            try FileManager.default.createDirectory(atPath: epDiagramsDirURL.path, withIntermediateDirectories: true, attributes: nil)
        }
        return epDiagramsDirURL
    }

    static func getDiagramDirURL(for filename: String) throws -> URL {
        let epDiagramsDirURL = try getEPDiagramsDirURL()
        let diagramDirURL = epDiagramsDirURL.appendingPathComponent(filename, isDirectory: true)
        if !FileManager.default.fileExists(atPath: diagramDirURL.path) {
            try FileManager.default.createDirectory(atPath: diagramDirURL.path, withIntermediateDirectories: true, attributes: nil)
        }
        return diagramDirURL
    }

    // non-throwing version of above
    static func getDiagramDirURLNonThrowing(for filename: String) -> URL? {
        return try? getDiagramDirURL(for: filename)
    }

    static func diagramDirURLExists(for filename: String) throws -> Bool {
        let epDiagramsDirURL = try getEPDiagramsDirURL()
        let diagramDirURL = epDiagramsDirURL.appendingPathComponent(filename, isDirectory: true)
        return FileManager.default.fileExists(atPath: diagramDirURL.path)
    }

    static func cleanupFilename(_ filename: String) -> String {
        var invalidCharacters = CharacterSet(charactersIn: ":/")
        invalidCharacters.formUnion(.newlines)
        invalidCharacters.formUnion(.illegalCharacters)
        invalidCharacters.formUnion(.controlCharacters)

        let newFilename = filename
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
        return newFilename
    }
}