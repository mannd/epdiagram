//
//  DiagramDocument.swift
//  EP Diagram
//
//  Created by David Mann on 11/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import OSLog

final class DiagramDocument: UIDocument {
    static let extensionName = "diagram"

    var diagram = Diagram.blankDiagram()
    var loadError: Error?

    deinit {
        print("*****DiagramDocument deinited*****")
    }

    func name() -> String {
        return fileURL.deletingPathExtension().lastPathComponent
    }

    override func contents(forType typeName: String) throws -> Any {
        let data: Data
        do {
            diagram.fileVersion = Diagram.FileVersion.defaultValue
            let encoder = JSONEncoder()
            data = try encoder.encode(diagram)
        } catch {
            throw DocumentError.archivingFailure
        }
        guard !data.isEmpty else {
            throw DocumentError.archivingFailure
        }
        return data
    }

    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        loadError = nil
        guard let data = contents as? Data else {
            let error = DocumentError.unrecognizedContent
            loadError = error
            throw error
        }

        let decoder = JSONDecoder()
        do {
            let fileVersion = try decoder.decode(DiagramFileVersion.self, from: data).fileVersion
            if let fileVersion = fileVersion, fileVersion > Diagram.FileVersion.defaultValue {
                let error = DocumentError.unsupportedFileVersion(fileVersion)
                loadError = error
                throw error
            }
            diagram = try decoder.decode(Diagram.self, from: data)
        } catch let error as DocumentError {
            loadError = error
            throw error
        } catch {
            let error = DocumentError.corruptDocument
            loadError = error
            throw error
        }
    }

    override func save(to url: URL, for saveOperation: UIDocument.SaveOperation, completionHandler: ((Bool) -> Void)? = nil) {
        let accessDirectoryURL = Sandbox.getPersistentDirectoryURL(forFileURL: url)
        let didStartAccessing = accessDirectoryURL?.startAccessingSecurityScopedResource() ?? false

        super.save(to: url, for: saveOperation) { success in
            if didStartAccessing {
                accessDirectoryURL?.stopAccessingSecurityScopedResource()
            }
            completionHandler?(success)
        }
    }

    override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
        os_log("handleError called: %s", log: OSLog.errors, type: .error, error.localizedDescription)
        print("error", error)
    }
}

private struct DiagramFileVersion: Decodable {
    let fileVersion: Int?
}

enum DocumentError: LocalizedError {
    case unrecognizedContent
    case corruptDocument
    case archivingFailure
    case unsupportedFileVersion(Int)

    var errorDescription: String? {
        switch self {
        case .unrecognizedContent:
            return L("File is an unrecognised format")
        case .corruptDocument:
            return L("File could not be read")
        case .archivingFailure:
            return L("File could not be saved")
        case .unsupportedFileVersion(let fileVersion):
            return L("This diagram file uses file version \(fileVersion), but this version of EP Diagram supports file versions up to \(Diagram.FileVersion.defaultValue).")
        }
    }
}
