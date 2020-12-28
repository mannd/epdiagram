//
//  DiagramDocument.swift
//  EP Diagram
//
//  Created by David Mann on 11/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import OSLog

enum DocumentError: Error {
  case unrecognizedContent
  case corruptDocument
  case archivingFailure

  var localizedDescription: String {
    switch self {

    case .unrecognizedContent:
      return L("File is an unrecognised format")
    case .corruptDocument:
      return L("File could not be read")
    case .archivingFailure:
      return L("File could not be saved")
    }
  }
}

class DiagramDocument: UIDocument {
    static let extensionName = "diagram"

    var diagram = Diagram.blankDiagram()

    func name() -> String {
        return fileURL.deletingPathExtension().lastPathComponent
    }

    override func contents(forType typeName: String) throws -> Any {
        let data: Data
        do {
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
        guard let data = contents as? Data else { throw DocumentError.unrecognizedContent }

        let decoder = JSONDecoder()
        do {
            diagram = try decoder.decode(Diagram.self, from: data)
        } catch {
            throw DocumentError.corruptDocument
        }
    }

    override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
        os_log("handleError called %s", log: OSLog.errors, type: .error, error.localizedDescription)
    }
}
