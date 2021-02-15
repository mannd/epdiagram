//
//  DiagramModelController.swift
//  EP Diagram
//
//  Created by David Mann on 2/13/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit
import Combine

class DiagramModelController: ObservableObject {
    var diagramViewController: DiagramViewController?
    @Published var diagram: Diagram {
        didSet {
            setLeftMargin(margin: diagram.ladder.leftMargin)
            // FIXME: Make undoable instead?
            diagramViewController?.currentDocument?.updateChangeCount(.done)
        }
    }

    init(diagram: Diagram, diagramViewController: DiagramViewController? = nil) {
        self.diagram = diagram
        self.diagramViewController = diagramViewController
    }

    func setLeftMargin(margin: CGFloat) {
        guard let diagramViewController = diagramViewController else { return }
        diagramViewController.ladderView.leftMargin = margin
        diagramViewController.cursorView.leftMargin = margin
        diagramViewController.imageScrollView.leftMargin = margin

    }
}
