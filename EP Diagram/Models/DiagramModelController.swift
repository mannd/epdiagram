//
//  DiagramModelController.swift
//  EP Diagram
//
//  Created by David Mann on 2/13/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit
import Combine

final class DiagramModelController: ObservableObject {
    var diagramViewController: DiagramViewController?
    @Published var diagram: Diagram {
        didSet {
            // Changes in diagram through preferences are not undoable, so just save as needed.
            diagramViewController?.currentDocument?.updateChangeCount(.done)
        }
    }

    init(diagram: Diagram, diagramViewController: DiagramViewController? = nil) {
        self.diagram = diagram
        self.diagramViewController = diagramViewController
    }
}
