//
//  DiagramViewController+HamburgerTableDelegate.swift
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
//    var diagramSaved: Bool { get }

    func takePhoto()
    func selectImage()
    func selectLadder()
    func renameDiagram()
    func about()
    func test()
    func snapshotDiagram()
    func getDiagramInfo()
    func lockLadder()
    func editLadder()
    func sampleDiagrams()
    func showPreferences()
    func editTemplates()
    func showHelp()
    func lockImage()
    func hideHamburgerMenu()
    func showHamburgerMenu()
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

extension DiagramViewController: HamburgerTableDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    var imageIsLocked: Bool {
        get { _imageIsLocked }
        set(newValue) { _imageIsLocked = newValue}
    }

    var diagramIsLocked: Bool {
        get { _ladderIsLocked }
        set(newValue) { _ladderIsLocked = newValue }
    }

    var constraintHamburgerLeft: NSLayoutConstraint {
        get { _constraintHamburgerLeft }
        set(newValue){ _constraintHamburgerLeft = newValue }
    }

    var constraintHamburgerWidth: NSLayoutConstraint {
        get { _constraintHamburgerWidth }
        set(newValue) { _constraintHamburgerWidth = newValue }
    }

    var maxBlackAlpha: CGFloat { _maxBlackAlpha }

    // MARK: - Delegate functions

    func takePhoto() {
        os_log("takePhoto()", log: OSLog.action, type: .info)
        handleTakePhoto()
    }

    func selectImage() {
        os_log("selectImage()", log: OSLog.action, type: .info)
        handleSelectImage()
    }

    func selectLadder() {
        os_log("selectLadder()", log: .action, type: .info)
        performSelectLadderSegue()
    }

    func renameDiagram() {
          os_log("renameDiagram()", log: .action, type: .info)
          // Just fail gracefully if name is nil, renameDiagram should not be available if name is nil.
        guard let diagramName = diagram.name, !diagramName.isBlank else { return }
        let alert = UIAlertController(title: L("Rename Diagram"), message: L("Enter a new name for diagram \(diagramName)"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil))
        alert.addTextField { textField in
            textField.placeholder = L("New diagram name")
        }
        alert.addAction(UIAlertAction(title: L("Rename"), style: .default) { [self] action in
            if let newName = alert.textFields?.first?.text {
                if let currentFileURL = currentDocument?.fileURL {
                    let newFileURL = currentFileURL.deletingLastPathComponent()
                        .appendingPathComponent(newName)
                        .appendingPathExtension(DiagramDocument.extensionName)
                    renameDocument(oldURL: currentFileURL, newURL: newFileURL)
                    diagram.name = newName
                    currentDocument?.updateChangeCount(.done)
                    delegate?.diagramEditorDidUpdateContent(self, diagram: diagram)
                    setTitle()
                }
            }
        })
        present(alert, animated: true)
      }

    func getDiagramInfo() {
        os_log("getDiagramInfo()", log: .action, type: .info)
        // TODO: If there are more fields, then include this and add SwiftUI view.
        // show dialog with diagram info here.
        P("Name = \(diagram.name ?? "unnamed")")
        P("Description = \(diagram.longDescription)")
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

    func lockImage() {
        imageIsLocked.toggle()
        // Turn off scrolling and zooming, but allow single taps to generate marks with cursors.
        imageScrollView.isScrollEnabled = !imageIsLocked
        imageScrollView.pinchGestureRecognizer?.isEnabled = !imageIsLocked
        cursorView.imageIsLocked = imageIsLocked
        cursorView.setNeedsDisplay()
        Sounds.playLockSound()
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

    func editLadder() {
        os_log("editLadder(action:)", log: OSLog.action, type: .info)
        performEditLadderSegue()
    }

    func editTemplates() {
        os_log("editTemplates()", log: OSLog.action, type: .info)
        performShowTemplateEditorSegue()
    }

    func showPreferences() {
        os_log("showPreferences()", log: OSLog.action, type: .info)
        performShowPreferencesSegue()
    }

    func showHelp() {
        os_log("showHelp()", log: OSLog.action, type: .info)
        performShowHelpSegue()
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

    // Use to test features during development
    #if DEBUG
    func test() {
        os_log("test()", log: .debugging, type: .debug)
        // delete all old diagrams
        //DiagramIO.deleteEPDiagramDir()
//        DiagramIO.deleteLadderTemplates()
        // toggle mark visibility
        //        ladderView.marksAreVisible.toggle()
        //        ladderView.setNeedsDisplay()
        DiagramIO.deleteCacheFiles()
    }
    #else
    func test() {}
    #endif

    // MARK: - Delegate handlers

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
    }

    func sampleDiagrams() {
        os_log("sampleDiagrams()", log: OSLog.action, type: .info)
        performShowSampleSelectorSegue()
    }

    private func resetLadder() {
        // FIXME: this makes ladder default ladder and it shouldn't.
        ladderView.resetLadder()
        undoManager?.removeAllActions()
        updateUndoRedoButtons()
        setViewsNeedDisplay()
    }

    @objc func setDiagramImage(_ image: UIImage?) {
        undoManager?.removeAllActions()
        currentDocument?.undoManager.registerUndo(withTarget: self, selector: #selector(setDiagramImage), object: imageView.image)
        updateUndoRedoButtons()
        diagram.ladder.clear()
        diagram.image = image
        setImageViewImage(with: image)
        imageScrollView.zoomScale = 1.0
        imageScrollView.contentOffset = CGPoint()
        cursorView.cursorIsVisible = false
        clearCalibration()
        setViewsNeedDisplay()
    }

 
    // MARK: - Hamburger menu functions

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
        cursorView.cursorIsVisible = false
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

extension DiagramViewController {
    static func freshController(diagram: Diagram? = nil, delegate: DiagramEditorDelegate) -> UINavigationController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let controller = storyboard.instantiateInitialViewController() as? UINavigationController else {
            fatalError("Project fault - cant instantiate ViewController from storyboard")
        }
        if let vc = controller.viewControllers.first as? DiagramViewController {
            vc.delegate = delegate
            vc.diagram = diagram ?? Diagram.blankDiagram()
        }
        return controller
    }
}


