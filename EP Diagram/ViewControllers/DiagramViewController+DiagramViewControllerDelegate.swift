//
//  DiagramViewController+DiagramViewControllerDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 5/31/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import CoreImage
import os.log

protocol DiagramViewControllerDelegate: class {
    func selectLadderTemplate(ladderTemplate: LadderTemplate?)
    func saveTemplates(_ templates: [LadderTemplate])
    func selectSampleDiagram(_ diagram: Diagram?)
    func setViewsNeedDisplay()
    func rotateImage(degrees: CGFloat)
    func resetImage()
    func showRotateToolbar()
}

extension DiagramViewController: DiagramViewControllerDelegate {
    // FIXME: need to make this undoable, going back to previous ladder (not just template).  See set diagram.image.
    func selectLadderTemplate(ladderTemplate: LadderTemplate?) {
        os_log("selecteLadderTemplate - ViewController", log: OSLog.action, type: .info)

        if let ladderTemplate = ladderTemplate {
            let ladder = Ladder(template: ladderTemplate)
            undoablySetLadder(ladder)
        }
    }

    @objc func undoablySetLadder(_ ladder: Ladder) {
        let oldLadder = diagram.ladder
        currentDocument?.undoManager.registerUndo(withTarget: self, selector: #selector(undoablySetLadder), object: oldLadder)
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        diagram.ladder = ladder
        ladderView.ladder = ladder
        setViewsNeedDisplay()
    }

    func undoablySetCalibration(_ calibration: Calibration) {
        let oldCalibration = self.calibration
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetCalibration(oldCalibration)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        self.calibration = calibration
    }

    func saveTemplates(_ templates: [LadderTemplate]) {
        os_log("saveTemplates()", log: .action, type: .info)
        DispatchQueue.global().async {
            do {
                try FileIO.store(templates, to: .documents, withFileName: FileIO.userTemplateFile)
            } catch {
                os_log("File error: %s", log: .errors, type: .error, error.localizedDescription)
                UserAlert.showFileError(viewController: self, error: error)
            }
        }
    }

    func selectSampleDiagram(_ diagram: Diagram?) {
        os_log("selectSampleDiagram()", log: .action, type: .info)
        guard let diagram = diagram else { return }
        // FIXME: This is not undoable
        loadSampleDiagram(diagram)
    }

    func setViewsNeedDisplay() {
        cursorView.setNeedsDisplay()
        ladderView.setNeedsDisplay()
        imageScrollView.setNeedsDisplay()
    }

    func rotateImage(degrees: CGFloat) {
        newRotateImage(radians: degrees.degreesToRadians)
        imageScrollView.resignFirstResponder()

    }

    func showRotateToolbar() {
        currentDocument?.undoManager.beginUndoGrouping() // will end when menu closed
        if rotateToolbarButtons == nil {
            let prompt = makePrompt(text: L("Rotate"))
            let rotate90RButton = UIBarButtonItem(title: L("90°R"), style: .plain, target: self, action: #selector(rotate90R))
            let rotate90LButton = UIBarButtonItem(title: L("90°L"), style: .plain, target: self, action: #selector(rotate90L))
            let rotate1RButton = UIBarButtonItem(title: L("1°R"), style: .plain, target: self, action: #selector(rotate1R))
            let rotate1LBButton = UIBarButtonItem(title: L("1°L"), style: .plain, target: self, action: #selector(rotate1L))
            let rotate01RButton = UIBarButtonItem(title: L("0.1°R"), style: .plain, target: self, action: #selector(rotate01R))
            let rotate01LButton = UIBarButtonItem(title: L("0.1°L"), style: .plain, target: self, action: #selector(rotate01L))
            let resetRotationButton = UIBarButtonItem(title: L("Reset"), style: .plain, target: self, action: #selector(resetImage))
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeRotateToolbar(_:)))
            rotateToolbarButtons = isIPad() || isRunningOnMac() ? [prompt, spacer, rotate90RButton, spacer, rotate90LButton, spacer, rotate1RButton, spacer, rotate1LBButton, spacer, rotate01RButton, spacer, rotate01LButton, spacer, resetRotationButton, spacer, doneButton] : [rotate90RButton, spacer, rotate90LButton, spacer, rotate1RButton, spacer, rotate1LBButton, spacer, rotate01RButton, spacer, rotate01LButton, spacer, doneButton] // leave out prompt and reset button so menu fits on iPhone SE2
        }
        setToolbarItems(rotateToolbarButtons, animated: false)
    }

    @objc func closeRotateToolbar(_ sender: UIAlertAction) {
        currentDocument?.undoManager.endUndoGrouping()
        showSelectToolbar()
    }

    @objc func rotate90R() {
        imageScrollView.rotateImage(degrees: 90)
    }

    @objc func rotate90L() {
        imageScrollView.rotateImage(degrees: -90)
    }

    @objc func rotate1R() {
        imageScrollView.rotateImage(degrees: 1)
    }

    @objc func rotate1L() {
        imageScrollView.rotateImage(degrees: -1)
    }

    @objc func rotate01R() {
        imageScrollView.rotateImage(degrees: 0.1)
    }

    @objc func rotate01L() {
        imageScrollView.rotateImage(degrees: -0.1)
    }

    @objc func doNothing() {

    }

    @objc func resetImage() {
        setTransform(transform: CGAffineTransform.identity)
        imageScrollView.resignFirstResponder()
    }

    func newRotateImage(radians: CGFloat) {
        let transform = self.imageView.transform.rotated(by: radians)
        setTransform(transform: transform)
    }

    func setTransform(transform: CGAffineTransform) {
        let originalTransform = self.imageView.transform
        currentDocument?.undoManager?.registerUndo(withTarget: self) { target in
            target.setTransform(transform: originalTransform)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        UIView.animate(withDuration: 0.4) {
            self.imageView.transform = transform
            self.diagram.transform = transform
//            self.imageScrollView.contentOffset = CGPoint.zero
//            self.imageView.sizeToFit()
            self.imageScrollView.contentInset = UIEdgeInsets(top: 0, left: self.leftMargin, bottom: 0, right: 0)
//            self.centerContent()
        }
    }

}

