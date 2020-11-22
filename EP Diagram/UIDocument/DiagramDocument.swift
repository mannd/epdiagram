//
//  DiagramDocument.swift
//  EP Diagram
//
//  Created by David Mann on 11/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

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

    var diagram = Diagram.defaultDiagram()

    override func contents(forType typeName: String) throws -> Any {
        let data: Data
        do {
            let encoder = JSONEncoder()
            data = try encoder.encode(diagram)
//            if let data = FileManager.default.contents(atPath: defaultDocumentURL.path) {
//                let documentData = try decoder.decode(Diagram.self, from: data)
//                return documentData
//            }
//            data = try NSKeyedArchiver.archivedData(withRootObject: diagram, requiringSecureCoding: false)
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

//
//        let unarchiver: NSKeyedUnarchiver
//        do {
//            unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        } catch {
            throw DocumentError.corruptDocument
        }
//        unarchiver.requiresSecureCoding = false
//        let decodedContent = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? Diagram
//        guard let content = decodedContent else { throw DocumentError.corruptDocument }
//
//        diagram = content
    }
}
