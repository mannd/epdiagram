//
//  Persistance.swift
//  EP Diagram
//
//  Created by David Mann on 5/19/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

// Based on this info from Apple: https://developer.apple.com/videos/play/tech-talks/204/ and this example class https://medium.com/@sdrzn/swift-4-codable-lets-make-things-even-easier-c793b6cf29e1

final class Persistance {
    enum Directory {
        case documents
        case cache
        case applicationSupport
    }

    enum PersistanceError: Error {
        case searchDirectoryNotFound
    }

    internal static func getURL(for directory: Directory) -> URL? {
        var searchDirectory : FileManager.SearchPathDirectory
        switch directory {
        case .documents:
            searchDirectory = .documentDirectory
        case .cache:
            searchDirectory = .cachesDirectory
        case .applicationSupport:
            searchDirectory = .applicationSupportDirectory
        }
        return FileManager.default.urls(for: searchDirectory, in: .userDomainMask).first
    }

    static func store<T: Encodable>(_ object: T, to directory: Directory, withFileName fileName: String) throws {
        guard let url = getURL(for: directory) else {
            os_log("Search directory not found", log: .default, type: .fault)
            throw PersistanceError.searchDirectoryNotFound
        }
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            // replace file with new data
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
        }
        catch let error {
            os_log("Encoding error %s", log: OSLog.default, type: .error, error.localizedDescription)
            throw error
        }
    }

    // TODO: maybe make this throw errors rather than just return nil on error?
    static func retrieve<T: Decodable>(_ fileName: String, from directory: Directory, as type: T.Type) -> T? {
        guard let url = getURL(for: directory) else { return nil }
        if !FileManager.default.fileExists(atPath: url.path) { return nil }
        if let data = FileManager.default.contents(atPath: url.path) {
            let decoder = JSONDecoder()
            let model = try? decoder.decode(type, from: data)
            return model
        }
        else {
            return nil
        }
    }

}

