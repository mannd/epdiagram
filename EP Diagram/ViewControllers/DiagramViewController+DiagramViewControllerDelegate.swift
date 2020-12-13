//
//  DiagramViewController+DiagramViewControllerDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 5/31/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

protocol DiagramViewControllerDelegate: class {
    func selectLadderTemplate(ladderTemplate: LadderTemplate?)
    func saveTemplates(_ templates: [LadderTemplate])
    func selectSampleDiagram(_ diagram: Diagram?)
    func setViewsNeedDisplay()
    func updatePreferences()
}

extension DiagramViewController: DiagramViewControllerDelegate {
    // FIXME: need to make this undoable, going back to previous ladder (not just template).  See set diagram.image.
    func selectLadderTemplate(ladderTemplate: LadderTemplate?) {
        os_log("selecteLadderTemplate - ViewController", log: OSLog.action, type: .info)
        P("ladder is dirty = \(ladderView.ladderIsDirty)")

        if let ladderTemplate = ladderTemplate {
            let ladder = Ladder(template: ladderTemplate)
            setLadder(ladder: ladder)
        }
    }

    func updatePreferences() {
        os_log("updatePreferences()", log: .action, type: .info)
        ladderView.lineWidth = CGFloat(UserDefaults.standard.double(forKey: Preferences.defaultLineWidthKey))
        ladderView.showBlock = UserDefaults.standard.bool(forKey: Preferences.defaultShowBlockKey)
        ladderView.showImpulseOrigin = UserDefaults.standard.bool(forKey: Preferences.defaultShowImpulseOriginKey)
        ladderView.showIntervals = UserDefaults.standard.bool(forKey: Preferences.defaultShowIntervalsKey)
        setViewsNeedDisplay()
    }

    private func setLadder(ladder: Ladder) {
        let oldLadder = diagram.ladder
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.setLadder(ladder: oldLadder)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        diagram.ladder = ladder
        ladderView.ladder = ladder
        setViewsNeedDisplay()
    }

    func saveTemplates(_ templates: [LadderTemplate]) {
        os_log("saveTemplates()", log: .action, type: .info)
        do {
            try FileIO.store(templates, to: .documents, withFileName: FileIO.userTemplateFile)
        } catch {
            os_log("File error: %s", log: .errors, type: .error, error.localizedDescription)
            Common.showFileError(viewController: self, error: error)
        }
    }

    func selectSampleDiagram(_ diagram: Diagram?) {
        os_log("selectSampleDiagram()", log: .action, type: .info)
        guard let diagram = diagram else { return }
        setDiagram(diagram)
    }

    func setDiagram(_ diagram: Diagram) {
        let oldDiagram = self.diagram
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.setDiagram(oldDiagram)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        self.diagram = diagram
        self.setImageViewImage(with: diagram.image)
        self.ladderView.ladder = diagram.ladder
        setTitle()
        setViewsNeedDisplay()
    }

    func setViewsNeedDisplay() {
        cursorView.setNeedsDisplay()
        ladderView.setNeedsDisplay()
    }
    

}
