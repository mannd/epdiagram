//
//  Persistance.swift
//  EP Diagram
//
//  Created by David Mann on 5/19/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

enum FileIOError: Error {
    case searchDirectoryNotFound
    case documentDirectoryNotFound
    case epDiagramDirectoryNotFound
    case diagramDirectoryNotFound
    case diagramIsUnnamed
    case duplicateDiagramName
    case diagramNameIsBlank
    case decodingFailed
    case encodingFailed
}

extension FileIOError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .searchDirectoryNotFound:
            return L("Search directory not found.")
        case .documentDirectoryNotFound:
            return L("User document directory not found.")
        case .epDiagramDirectoryNotFound:
            return L("EP Diagram directory not found.")
        case .diagramDirectoryNotFound:
            return L("Diagram directory not found.")
        case .diagramIsUnnamed:
            return L("Diagram has no name.")
        case .duplicateDiagramName:
            return L("Diagram name is a duplicate.")
        case .diagramNameIsBlank:
            return L("Diagram name can't be blank.")
        case .decodingFailed:
            return L("Decoding failed.")
        case .encodingFailed:
            return L("Encoding failed.")
        }
    }
}

// Based on this info from Apple: https://developer.apple.com/videos/play/tech-talks/204/ and this example class https://medium.com/@sdrzn/swift-4-codable-lets-make-things-even-easier-c793b6cf29e1

final class FileIO {
    // Where ladder templates are stored.
    static let userTemplateFile = "epdiagram_ladder_templates"
    // Directory where save diagrams.
    static let epDiagramDir = "epdiagram"
    static let imageFilename = "image.png"
    static let ladderFilename = "ladder.json"
    static let restorationDir = "restoration"

    enum Directory {
        case documents
        case cache
        case applicationSupport
    }

    private static func getURL(for directory: Directory) -> URL? {
        var searchDirectory : FileManager.SearchPathDirectory
        switch directory {
        case .documents:
            searchDirectory = .documentDirectory
        case .cache:
            searchDirectory = .cachesDirectory
        case .applicationSupport:
            searchDirectory = .applicationSupportDirectory
        }
        let ubiqURL = (UIApplication.shared.delegate as? AppDelegate)?.ubiqURL
        if let ubiqURL = ubiqURL, directory == .documents {
            return ubiqURL
        } else {
            return FileManager.default.urls(for: searchDirectory, in: .userDomainMask).first
        }
    }

    static func getDocumentsURL() -> URL? {
        return getURL(for: .documents)
    }

    static func getCacheURL() -> URL? {
        return getURL(for: .cache)
    }

    static func store<T: Encodable>(_ object: T, to directory: Directory, withFileName fileName: String, subDirectory: String? = nil) throws {
        guard var url = getDocumentsURL() else {
            os_log("Search directory not found", log: .default, type: .fault)
            throw FileIOError.searchDirectoryNotFound
        }
        if let subDirectory = subDirectory {
            url = url.appendingPathComponent(subDirectory)
        }
        let fileURL = url.appendingPathComponent(fileName)
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            // replace file with new data
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil)
        }
        catch let error {
            os_log("Encoding error %s", log: OSLog.default, type: .error, error.localizedDescription)
            throw error
        }
    }

    static func retrieve<T: Decodable>(_ fileName: String, from directory: Directory, subDirectory: String? = nil, as type: T.Type) -> T? {
        guard var url = getDocumentsURL() else { return nil }
        if let subDirectory = subDirectory {
            url = url.appendingPathComponent(subDirectory)
        }
        let fileURL = url.appendingPathComponent(fileName)
        if !FileManager.default.fileExists(atPath: fileURL.path) { return nil }
        if let data = FileManager.default.contents(atPath: fileURL.path) {
            let decoder = JSONDecoder()
            let model = try? decoder.decode(type, from: data)
            return model
        }
        else {
            return nil
        }
    }
    
    static func remove(_ fileName: String, from directory: Directory) {
        if let url = getURL(for: directory)?.appendingPathComponent(fileName, isDirectory: false) {
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    fatalError(error.localizedDescription)
                }
            }
        }
    }

    static func fileExists(_ fileName: String, in directory: Directory) -> Bool {
        if let url = getURL(for: directory)?.appendingPathComponent(fileName, isDirectory: false) {
             return FileManager.default.fileExists(atPath: url.path)
        } else { return false }
     }

    static func enumerateDirectory(_ url: URL) -> [String] {
        var paths: [String] = []
        if let enumerator = FileManager.default.enumerator(atPath: url.path) {
            for case let path as String in enumerator {
                paths.append(path)
            }
        }
        return paths
    }

}

