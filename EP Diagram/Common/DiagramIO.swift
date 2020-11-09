//
//  DiagramIO.swift
//  EP Diagram
//
//  Created by David Mann on 7/14/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import Foundation
import os.log

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

    static func saveLastDiagram(name: String?) {
        let preferences = UserDefaults.standard
        preferences.set(name, forKey: Preferences.defaultLastDiagramKey)
    }

    // for debugging only!
    static func deleteEPDiagramDir() {
        do {
            let url = try getEPDiagramsDirURL()
            try FileManager.default.removeItem(at: url)
        } catch {
            os_log("deleteEPDiagramDir() error %s", log: .errors, type: .error, error.localizedDescription)
        }
    }

    static func deleteCacheFiles() {
        if let url = FileIO.getURL(for: .cache) {
            let paths = FileIO.enumerateDirectory(url)
            for path in paths {
                FileIO.remove(path, from: .cache)
            }
        }
    }

    static func deleteLadderTemplates() {
        do {
            if let url = FileIO.getURL(for: .documents) {
                let templateFileURL = url.appendingPathComponent(FileIO.userTemplateFile)
                try FileManager.default.removeItem(at: templateFileURL)
            }
        } catch {
            os_log("deleteLadderTemplates() error %s", log: .errors, type: .error, error.localizedDescription)
        }
    }

    static let restorationDir = ""
    static func getRestorationURL() -> URL? {
        guard let cacheURL = FileIO.getURL(for: .cache) else { return nil }
        let restorationURL =  cacheURL.appendingPathComponent(restorationDir)
        return restorationURL
    }
}
