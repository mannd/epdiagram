//
//  LadderTemplatesModelController.swift
//  EP Diagram
//
//  Created by David Mann on 2/14/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit
import Combine
import os.log

final class LadderTemplatesModelController: ObservableObject {
    let viewController: UIViewController?
    @Published var ladderTemplates: [LadderTemplate] = [] {
        didSet {
            print("ladder templates changed")
            saveTemplates()
        }
    }

    init(ladderTemplates: [LadderTemplate], viewController: UIViewController? = nil) {
        self.viewController = viewController
        self.ladderTemplates = ladderTemplates
    }

    init(viewController: UIViewController? = nil) {
        self.viewController = viewController
        self.ladderTemplates = LadderTemplate.templates()
    }

    func saveTemplates() {
        os_log("saveTemplates()", log: .action, type: .info)
        do {
            try FileIO.store(ladderTemplates, to: .documents, withFileName: FileIO.userTemplateFile)
        } catch {
            os_log("File error: %s", log: .errors, type: .error, error.localizedDescription)
            if let viewController = viewController {
                UserAlert.showFileError(viewController: viewController, error: error)
            }
        }
    }
}
