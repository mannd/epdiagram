//
//  LadderTemplatesModelController.swift
//  EP Diagram
//
//  Created by David Mann on 2/14/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import Foundation
import Combine
import os.log

class LadderTemplatesModelController: ObservableObject {
    @Published var ladderTemplates: [LadderTemplate] = [] {
        didSet {
            print("ladder templates changed")
            saveTemplates()
        }
    }

    init(ladderTemplates: [LadderTemplate]) {
        self.ladderTemplates = ladderTemplates
    }

    init?() {
        var ladderTemplates = FileIO.retrieve(FileIO.userTemplateFile, from: .documents, as: [LadderTemplate].self) ?? LadderTemplate.defaultTemplates()
        if ladderTemplates.isEmpty {
            ladderTemplates = LadderTemplate.defaultTemplates()
        }
        self.ladderTemplates = ladderTemplates
    }

    func saveTemplates() {
        os_log("saveTemplates()", log: .action, type: .info)
        do {
            try FileIO.store(ladderTemplates, to: .documents, withFileName: FileIO.userTemplateFile)
        } catch {
            os_log("File error: %s", log: .errors, type: .error, error.localizedDescription)
//            UserAlert.showFileError(viewController: self, error: error)
        }
    }
}
