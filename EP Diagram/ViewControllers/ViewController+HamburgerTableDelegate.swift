//
//  ViewController+HamburgerTableDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 4/17/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

protocol HamburgerTableDelegate: class {
    var hamburgerMenuIsOpen: Bool { get set }
    var constraintHamburgerLeft: NSLayoutConstraint { get set }
    var constraintHamburgerWidth: NSLayoutConstraint { get set }
    var maxBlackAlpha: CGFloat { get }
    var imageIsLocked: Bool { get set }
    var diagramIsLocked: Bool { get set }
    var diagramSaved: Bool { get }

    func takePhoto()
    func selectImage()
    func selectLadder()
    func about()
    func test()
    func newDiagram()
    func selectDiagram()
    func saveDiagram(completion: (()->Void)?)
    func snapshotDiagram()
    func renameDiagram()
    func duplicateDiagram()
    func getDiagramInfo()
    func lockLadder()
    func sampleDiagrams()
    func showPreferences()
    func editTemplates()
    func help()
    func lockImage()
    func hideHamburgerMenu()
    func showHamburgerMenu()
}

// MARK: -

extension HamburgerTableDelegate {
    // This allows the saveDiagram completition to be nil.
    func saveDiagram(completion: (()->Void)? = nil) {
        saveDiagram(completion: completion)
    }
}

// MARK: -

// Helper class to allow saving images to Photo Album.
class ImageSaver: NSObject {
    var viewController: UIViewController?

    func writeToPhotoAlbum(image: UIImage, viewController: UIViewController) {
        self.viewController = viewController
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(showSavedImageResult), nil)
    }

    @objc func showSavedImageResult(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let title: String
        let message: String
        if let error = error {
            os_log("Error saving snapshot:  %s", log: .errors, type: .error,   error.localizedDescription)
            title = L("Error Saving Snapshot")
            message = L("Make sure you have allowed EP Diagram to save to the Photos Library in the Settings app.  Error message: \(error.localizedDescription)")
        } else {
            Sounds.playShutterSound()
            // See https://www.hackingwithswift.com/books/ios-swiftui/how-to-save-images-to-the-users-photo-library
            os_log("Snapshot successfully saved.", log: .action, type: .info)
            title = L("Diagram Snapshot Saved")
            message = L("Diagram snapshot saved to Photo Library.")
        }
        if let viewController = viewController {
            Common.showMessage(viewController: viewController, title: title, message: message)
        }
    }
}

// MARK: -

extension ViewController: HamburgerTableDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    var imageIsLocked: Bool {
        get { _imageIsLocked }
        set(newValue) { _imageIsLocked = newValue}
    }

    var diagramIsLocked: Bool {
        get { _ladderIsLocked }
        set(newValue) { _ladderIsLocked = newValue }
    }

    var diagramSaved: Bool { diagram.isSaved }

    var constraintHamburgerLeft: NSLayoutConstraint {
        get { _constraintHamburgerLeft }
        set(newValue){ _constraintHamburgerLeft = newValue }
    }

    var constraintHamburgerWidth: NSLayoutConstraint {
        get { _constraintHamburgerWidth }
        set(newValue) { _constraintHamburgerWidth = newValue }
    }

    var maxBlackAlpha: CGFloat { _maxBlackAlpha }

    func lockImage() {
        imageIsLocked.toggle()
        // Turn off scrolling and zooming, but allow single taps to generate marks with cursors.
        imageScrollView.isScrollEnabled = !imageIsLocked
        imageScrollView.pinchGestureRecognizer?.isEnabled = !imageIsLocked
        cursorView.imageIsLocked = imageIsLocked
        cursorView.setNeedsDisplay()
        Sounds.playLockSound()
    }

    func takePhoto() {
        os_log("takePhoto()", log: OSLog.action, type: .info)
            handleDirtyLadder(
                title: L("Take Photo"),
                message: L("Diagram has changes.  You can save it and then take a photo, or abandon the changes and take a photo."),
                handler: handleTakePhoto)
    }

    private func handleDirtyLadder(title: String, message: String, handler: @escaping ()->Void) {
        if ladderView.ladderIsDirty {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil)
            let selectWithSaveAction = UIAlertAction(title: L("Save Diagram First"), style: .default, handler: { action in
                self.dismiss(animated: true, completion: nil)
                self.saveDiagram(completion: { handler() })
            })
            let selectWithoutSaveAction = UIAlertAction(title: L("Don't Save Diagram"), style: .destructive, handler: { action in
                self.dismiss(animated: true, completion: nil)
                handler() })
            alert.addAction(cancelAction)
            alert.addAction(selectWithSaveAction)
            alert.addAction(selectWithoutSaveAction)
            present(alert, animated: true)
        } else {
            handler()
        }
    }

    private func handleTakePhoto() {
        os_log("takePhoto()", log: OSLog.action, type: .info)
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.modalPresentationStyle = .fullScreen
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            Common.showMessage(
                viewController: self,
                title: L("Camera error"),
                message: L("Camera not available"))
            os_log("Camera not available", log: .debugging, type: .debug)
            return
        }
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true)
    }

    private func handleSelectImage() {
        os_log("handleSelectImage()", log: .action, type: .info)
        if !UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            Common.showMessage(
                viewController: self,
                title: L("Photo Library Not Available"),
                message: L("Make sure you have enabled permission for EP Diagram to use the Photo Library in the Settings app."))
            os_log("Photo library not available", log: .debugging, type: .debug)
            return
        }
        // By default picker.mediaTypes == ["public.image"], i.e. videos aren't shown.  So no need to check UIImagePickerController.availableMediaTypes(for:) or set picker.mediaTypes.
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        // TODO: Test editing on real devices (doesn't work on simulator).
        // Must allow editing because edited image is used by UIImagePickerController delegate.
        imagePicker.allowsEditing = true
        // Need to use popover for iPads, according to docs, but .fullscreen seems to work too.
        if UIDevice.current.userInterfaceIdiom == .pad {
            imagePicker.modalPresentationStyle = .popover
            imagePicker.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        }
        present(imagePicker, animated: true)

//        handleNewDiagram()
//        newDiagram()
//        resetLadder()
    }

    func selectImage() {
        os_log("selectImage()", log: OSLog.action, type: .info)
            handleDirtyLadder(
                title: L("Select Image"),
                message: L("Diagram has changes.  You can save it and then select an image, or abandon the changes and select an image."),
                handler: handleSelectImage)
    }

    func about() {
        let versionBuild = Version.getAppVersion()
        let version = versionBuild.version ?? L("unknown")
        let build = versionBuild.build ?? L("unknown")
        os_log("EP Diagram: version = %s build = %s", log: OSLog.debugging, type: .info, version, build)
        Common.showMessage(
            viewController: self,
            title: L("EP Diagram"),
            message: L("Copyright 2020 EP Studios, Inc.\nVersion \(version)"))
    }

    // FIXME: remove before release!!!!!
    // Use to test features during development
    #if DEBUG
    func test() {
        os_log("test()", log: .debugging, type: .debug)
        // delete all old diagrams
        DiagramIO.deleteEPDiagramDir()
        // toggle mark visibility
//        ladderView.marksAreVisible.toggle()
//        ladderView.setNeedsDisplay()
    }
    #else
    func test() {}
    #endif

    // Save old diagram, keep image, clear ladder.
    func newDiagram() {
        os_log("newDiagram()", log: .action, type: .info)
            handleDirtyLadder(
                title: L("New Diagram"),
                message: L("Diagram has changes.  You can save it before starting a new diagram, or abandon the changes and start a new diagram."),
                handler: handleNewDiagram)
    }

    // TODO: Need to do other things here, e.g. reset zoom to 1.0, etc.
    private func handleNewDiagram() {
        os_log("handleNewDiagram()", log: .action, type: .info)
        // Use same ladder, blank out image.
        diagram = Diagram.defaultDiagram()
        imageView.image = diagram.image
        ladderView.ladder = diagram.ladder
        setViewsNeedDisplay()
    }

    // Save old diagram, load selected image and ladder.
    func selectDiagram() {
        os_log("selectDiagram()", log: OSLog.action, type: .info)
        // TODO: change all ladderView.isDirty to diagram.isDirty.
            handleDirtyLadder(
                title: L("Select Diagram"),
                message:L("Diagram has changes.  You can save it before selecting a new diagram, or abandon the changes and select a new diagram."),
                handler: handleSelectDiagram)
    }

    private func handleSelectDiagram() {
        do {
            let epDiagramsDirURL = try DiagramIO.getEPDiagramsDirURL()
            let fileURLs = try FileManager.default.contentsOfDirectory(at: epDiagramsDirURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            if fileURLs.count < 1 {
                Common.showMessage(
                    viewController: self,
                    title: L("No Saved Diagrams"),
                    message: L("No previously saved diagrams found."))
                return
            }
            let filenames = fileURLs.map { $0.lastPathComponent }.sorted()
            diagramFilenames = filenames
            performShowDiagramSelectorSegue()
        } catch {
            os_log("Error: %s", error.localizedDescription)
        }
    }

    func snapshotDiagram() {
        let topRenderer = UIGraphicsImageRenderer(size: imageScrollView.bounds.size)
        let originX = imageScrollView.bounds.minX - imageScrollView.contentOffset.x
        let originY = imageScrollView.bounds.minY - imageScrollView.contentOffset.y
        let bounds = CGRect(x: originX, y: originY, width: imageScrollView.bounds.width, height: imageScrollView.bounds.height)
        let topImage = topRenderer.image { ctx in
            imageScrollView.drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        let bottomRenderer = UIGraphicsImageRenderer(size: ladderView.bounds.size)
        let bottomImage = bottomRenderer.image { ctx in
            ladderView.drawHierarchy(in: ladderView.bounds, afterScreenUpdates: true)
        }
        let size = CGSize(width: ladderView.bounds.size.width, height: imageScrollView.bounds.size.height + ladderView.bounds.size.height)
        UIGraphicsBeginImageContext(size)
        let topRect = CGRect(x: 0, y: 0, width: ladderView.bounds.size.width, height: imageScrollView.bounds.size.height)
        topImage.draw(in: topRect)
        let bottomRect = CGRect(x: 0, y: imageScrollView.bounds.size.height, width: ladderView.bounds.size.width, height: ladderView.bounds.size.height)
        bottomImage.draw(in: bottomRect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let newImage = newImage {
            let imageSaver = ImageSaver()
            imageSaver.writeToPhotoAlbum(image: newImage, viewController: self)
        }
    }

    func getDiagramInfo() {
        os_log("getDiagramInfo()", log: .action, type: .info)
        // TODO: If there are more fields, then include this and add SwiftUI view.
        // show dialog with diagram info here.
        P("Name = \(diagram.name ?? "unnamed")")
        P("Description = \(diagram.description)")
        P("isDirty = \(diagram.isDirty)")
        P("isSaved = \(diagram.isSaved)")
    }

    func lockLadder() {
        os_log("lockDiagram()", log: .action, type: .info)
        _ladderIsLocked.toggle()
        // Turn off scrolling and zooming, but allow single taps to generate marks with cursors.
        ladderView.ladderIsLocked = _ladderIsLocked
        cursorView.allowTaps = !_ladderIsLocked
        ladderView.isUserInteractionEnabled = !_ladderIsLocked
        setViewsNeedDisplay()
        Sounds.playLockSound()
    }

    // see https://stackoverflow.com/questions/38579679/warning-attempt-to-present-uiimagepickercontroller-on-which-is-alread
    func saveDiagram(completion: (()->Void)? = nil) {
        os_log("saveDiagram()", log: OSLog.action, type: .info)
        // FIXME: refactor out the huge guard.
        guard let diagramName = diagram.name, !diagramName.isBlank else {
            let alert = UIAlertController(title: L("Save Diagram"), message: L("Give a name and optional description to this diagram"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: L("Cancel"), style: .cancel))
            alert.addTextField { textField in
                textField.placeholder = L("Diagram name")
                textField.text = self.diagram.name
            }
            alert.addTextField { textField in
                textField.placeholder = L("Diagram description")
                textField.text = self.diagram.description
            }
            alert.addAction(UIAlertAction(title: L("Save"), style: .default) { action in
                if let name = alert.textFields?.first?.text, let description = alert.textFields?[1].text {
                    do {
                        if try DiagramIO.diagramDirURLExists(for: name) {
                            throw FileIOError.duplicateDiagramName
                        }
                        self.diagram.name = name
                        self.diagram.description = description
                        try self.doSaveDiagram()
                        if let completion = completion {
                            completion()
                        }
                    } catch FileIOError.duplicateDiagramName {
                        Common.showMessage(
                            viewController: self,
                            title: L("Duplicate Diagram Name"),
                            message: L("Please choose a different name.  This name is a duplicate and would overwrite the diagram with this name."))
                    } catch {
                        Common.showFileError(viewController: self, error: error)
                        self.diagram.name = nil
                        self.diagram.description = ""
                    }
                }
            })
            present(alert, animated: true)
            return
        }
        do {
            try doSaveDiagram()
            if let completion = completion {
                completion()
            }
        }
        catch {
            os_log("Error: %s", log: .errors, type: .error, error.localizedDescription)
            Common.showFileError(viewController: self, error: error)
        }
    }

    private func doSaveDiagram() throws {
        try diagram.save()
        DiagramIO.saveLastDiagram(name: diagram.name)
        setTitle()
    }

    func renameDiagram() {
        os_log("renameDiagram()", log: .action, type: .info)
        // Just fail gracefully if name is nil, renameDiagram should not be available if name is nil.
        guard let name = diagram.name, !name.isBlank else { return }
        let alert = UIAlertController(title: L("Rename Diagram"), message: L("Enter a new name for diagram \(name)"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil))
        alert.addTextField { textField in
            textField.placeholder = L("New diagram name")
        }
        alert.addAction(UIAlertAction(title: L("Rename"), style: .default) { action in
            if let name = alert.textFields?.first?.text {
                do {
                    try self.diagram.rename(newName: name)
                    self.setTitle()
                } catch {
                    Common.showFileError(viewController: self, error: error)
                }
            }
        })
        present(alert, animated: true)
    }

    func duplicateDiagram() {
        os_log("duplicateDiagram()", log: .action, type: .info)
        // Just fail gracefully if name is nil, renameDiagram should not be available if name is nil.
        guard let name = diagram.name, !name.isBlank else { return }
        let alert = UIAlertController(title: L("Duplicate Diagram"), message: L("Enter a name for duplicate diagram of \(name)"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil))
        alert.addTextField { textField in
            textField.placeholder = L("Duplicate diagram name")
        }
        alert.addAction(UIAlertAction(title: L("Duplicate"), style: .default) { action in
            if let name = alert.textFields?.first?.text {
                do {
                    try self.diagram.duplicate(duplicateName: name)
                    self.setTitle()
                } catch {
                    Common.showFileError(viewController: self, error: error)
                }
            }
        })
        present(alert, animated: true)
    }

    func sampleDiagrams() {
        os_log("sampleDiagrams()", log: OSLog.action, type: .info)
            handleDirtyLadder(
                title: L("Select Sample Diagram"),
                message: L("Diagram has changes.  You can save it and then select a sample diagram, or abandon the changes and select a sample diagram."),
                handler: performShowSampleSelectorSegue)
    }

    func showPreferences() {
        os_log("showPreferences()", log: OSLog.action, type: .info)
        performShowPreferencesSegue()
    }

    private func resetLadder() {
        ladderView.resetLadder()
        undoManager?.removeAllActions()
        updateUndoRedoButtons()
        setViewsNeedDisplay()
    }

    func editTemplates() {
        os_log("editTemplates()", log: OSLog.action, type: .info)
        performShowTemplateEditorSegue()
    }

    func help() {
        os_log("help()", log: OSLog.action, type: .info)
        performShowHelpSegue()
    }

    @objc func toggleHamburgerMenu() {
        if hamburgerMenuIsOpen {
            hideHamburgerMenu()
        } else {
            showHamburgerMenu()
        }
    }

    func showHamburgerMenu() {
        os_log("showHamburgerMenu()", log: OSLog.action, type: .info)
        hamburgerTableViewController?.reloadData()
        constraintHamburgerLeft.constant = 0
        hamburgerMenuIsOpen = true
        self.separatorView?.removeFromSuperview()
        self.separatorView = nil
        navigationController?.setToolbarHidden(true, animated: true)
        // Always hide cursor when opening hamburger menu.
        cursorView.hideCursor(true)
        cursorView.setNeedsDisplay()
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
            self.blackView.alpha = self.maxBlackAlpha
        })
    }

    func hideHamburgerMenu() {
        os_log("hideHamburgerMenu()", log: OSLog.action, type: .info)
        constraintHamburgerLeft.constant = -self.constraintHamburgerWidth.constant;
        hamburgerMenuIsOpen = false
        navigationController?.setToolbarHidden(false, animated: true)
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
            self.blackView.alpha = 0
        }, completion: { (finished:Bool) in
            self.separatorView = HorizontalSeparatorView.addSeparatorBetweenViews(separatorType: .horizontal, primaryView: self.imageScrollView, secondaryView: self.ladderView, parentView: self.view)
        })
    }

    private func setDiagramImage(_ image: UIImage?) {
        diagram.ladder.clear()
        diagram.image = image
        imageView.image = image
        imageScrollView.zoomScale = 1.0
        imageScrollView.contentOffset = CGPoint()
        cursorView.clearCalibration()
        setViewsNeedDisplay()
    }

    // MARK: - UIImagePickerController delegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let chosenImage = info[.editedImage] as? UIImage
        setDiagramImage(chosenImage)
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

