//
//  DiagramViewController+HamburgerTableDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 4/17/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers
import AVFoundation
import os.log

protocol HamburgerTableDelegate: class {
    var hamburgerMenuIsOpen: Bool { get set }
    var constraintHamburgerLeft: NSLayoutConstraint { get set }
    var constraintHamburgerWidth: NSLayoutConstraint { get set }
    var maxBlackAlpha: CGFloat { get }
    var imageIsLocked: Bool { get set }
    var ladderIsLocked: Bool { get set }

    func takePhoto()
    func selectImage()
    func selectLadder()
    func renameDiagram()
    func about()
    func debug()
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
            // See https://www.hackingwithswift.com/books/ios-swiftui/how-to-save-images-to-the-users-photo-library
            os_log("Snapshot successfully saved.", log: .action, type: .info)
            title = L("Diagram Snapshot Saved")
            message = L("Diagram snapshot saved to Photo Library.")
        }
        if let viewController = viewController {
            UserAlert.showMessage(viewController: viewController, title: title, message: message)
        }
    }
}

// MARK: -

extension DiagramViewController: HamburgerTableDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate, UIDocumentPickerDelegate {
    
    var imageIsLocked: Bool {
        get { _imageIsLocked }
        set { _imageIsLocked = newValue}
    }

    var ladderIsLocked: Bool {
        get { _ladderIsLocked }
        set { _ladderIsLocked = newValue }
    }

    var constraintHamburgerLeft: NSLayoutConstraint {
        get { _constraintHamburgerLeft }
        set { _constraintHamburgerLeft = newValue }
    }

    var constraintHamburgerWidth: NSLayoutConstraint {
        get { _constraintHamburgerWidth }
        set { _constraintHamburgerWidth = newValue }
    }

    var maxBlackAlpha: CGFloat { _maxBlackAlpha }

    // MARK: - Delegate functions

    func takePhoto() {
        os_log("takePhoto()", log: OSLog.action, type: .info)
        checkCameraPermissions()
    }

    func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            os_log("Camera access not determined", log: .default, type: .default)
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.handleTakePhoto()
                    }

                }
            })
        case .restricted:
            os_log("Camera access restricted", log: .default, type: .default)
        case .denied:
            os_log("Camera access denied", log: .default, type: .default)
            UserAlert.showMessage(viewController: self, title: L("Camera Permission Denied"), message: L("Please set camera permission in Settings app."))
        case .authorized:
            os_log("Camera access authorized", log: .default, type: .default)
            self.handleTakePhoto()
        @unknown default:
            fatalError("Unhandled default in checkCameraPermissions()")
        }
    }

    func selectImage() {
        os_log("selectImage()", log: OSLog.action, type: .info)
        chooseSource()
    }

    func selectLadder() {
        os_log("selectLadder()", log: .action, type: .info)
        performSelectLadderSegue()
    }

    func renameDiagram() {
          os_log("renameDiagram()", log: .action, type: .info)
          // Just fail gracefully if name is nil, renameDiagram should not be available if name is nil.
        guard let diagramName = currentDocument?.name(), !diagramName.isBlank else { return }
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
                    diagramEditorDelegate?.diagramEditorDidUpdateContent(self, diagram: diagram)
                    setTitle()
                }
            }
        })
        present(alert, animated: true)
      }

    func getDiagramInfo() {
        os_log("getDiagramInfo()", log: .action, type: .info)
        // Consider killing this.  Files app gives file info.
        var message: String = ""
        if let currentDocument = currentDocument {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium

            message += L("File name = \(currentDocument.localizedName)")
            if let fileModificationDate = currentDocument.fileModificationDate {
                let formattedDate = dateFormatter.string(from: fileModificationDate)
                message += L("\nLast modified = \(formattedDate)")
            }
            message +=
                L("""
                \nDescription = \(diagram.longDescription)
                Diagram file version = \(diagram.fileVersion)
                Ladder name = \(diagram.ladder.name)
                Ladder description = \(diagram.ladder.longDescription)
                """)
        }
        else {
            message = L("Could not get diagram file information")
        }
        UserAlert.showMessage(viewController: self, title: L("Diagram Info"), message: message)
    }


    func lockImage() {
        imageIsLocked.toggle()
        // Turn off scrolling and zooming, but allow single taps to generate marks with cursors.
        imageScrollView.isScrollEnabled = !imageIsLocked
        imageScrollView.pinchGestureRecognizer?.isEnabled = !imageIsLocked
        cursorView.imageIsLocked = imageIsLocked
        cursorView.setNeedsDisplay()
        if playSounds {
            Sounds.playLockSound()
        }
    }

    func lockLadder() {
        os_log("lockDiagram()", log: .action, type: .info)
        _ladderIsLocked.toggle()
        // Turn off scrolling and zooming, but allow single taps to generate marks with cursors.
        ladderView.ladderIsLocked = _ladderIsLocked
        cursorView.allowTaps = !_ladderIsLocked
        ladderView.isUserInteractionEnabled = !_ladderIsLocked
        updateToolbarButtons()
        setViewsNeedDisplay()
        if playSounds {
            Sounds.playLockSound()
        }
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
        let versionBuild = Version.appVersion()
        let version = versionBuild.version ?? L("unknown")
        let build = versionBuild.build ?? L("unknown")
        //let prereleaseVersion = Version.prereleaseVersion
        os_log("EP Diagram: version = %s build = %s", log: OSLog.debugging, type: .info, version, build)
        // OK to remove code below once release version is published.
        //var prereleaseMessage = ""
        //if let prereleaseVersion = prereleaseVersion {
        //    prereleaseMessage = "\nPrerelease version \(prereleaseVersion)+\(build)"
        //}
        UserAlert.showMessage(
            viewController: self,
            title: L("EP Diagram"),
            message: L("Copyright 2021 EP Studios, Inc." + "\nVersion \(version)"))
    }

    // Use to test features during development
    #if DEBUG
    func debug() {
        os_log("debug()", log: .debugging, type: .debug)
        ladderView.relinkAllMarks()
        ladderView.assessGlobalImpulseOrigin()
        setViewsNeedDisplay()

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
            UserAlert.showMessage(
                viewController: self,
                title: L("Camera error"),
                message: L("Camera not available"))
            os_log("Camera not available", log: .debugging, type: .debug)
            return
        }
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true)
    }

    private func chooseSource() {
        let alert = UIAlertController(title: NSLocalizedString("Image Source", comment: ""), message:nil, preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .popover
        alert.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        alert.addAction(UIAlertAction(title: NSLocalizedString("Photos", comment: ""), style: .default, handler: { _ in
            self.handleSelectImage()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Files", comment: ""), style: .default, handler: { _ in
            self.handleSelectFile()
        }))
        alert.addAction(UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func handleSelectFile() {
        let supportedTypes: [UTType] = [UTType.image, UTType.pdf]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        documentPicker.delegate = self

        // Set the initial directory.
        documentPicker.directoryURL = FileIO.getDocumentsURL()

        // Present the document picker.
        present(documentPicker, animated: true, completion: nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.openURL(url: urls[0])
    }

    private func handleSelectImage() {
        os_log("handleSelectImage()", log: .action, type: .info)
        presentPhotosForImages()
    }

    func sampleDiagrams() {
        os_log("sampleDiagrams()", log: OSLog.action, type: .info)
        performShowSampleSelectorSegue()
    }

    @objc func undoablySetDiagramImage(_ image: UIImage?,
                                       imageIsUpscaled: Bool,
                                       transform: CGAffineTransform,
                                       scale: CGFloat,
                                       contentOffset: CGPoint) {
        os_log("setDiagramImage(_:)", log: .debugging, type: .info)

        let oldImage = self.imageView.image
        let oldImageIsUpscaled = diagram.imageIsUpscaled
        let oldTransform = self.imageView.transform
        let oldScale = self.imageScrollView.zoomScale
        let oldContentOffset = self.imageScrollView.contentOffset
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetDiagramImage(oldImage, imageIsUpscaled: oldImageIsUpscaled, transform: oldTransform, scale: oldScale, contentOffset: oldContentOffset)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)

        diagram.imageIsUpscaled = imageIsUpscaled
        let scaledImage = scaleImageForImageView(image)
        diagram.image = scaledImage
        imageView.image = scaledImage
        imageScrollView.zoomScale = scale
        imageView.transform = transform
        diagram.transform = transform
        // handle imageScrollView sometimes ignoring contentInset and plastering
        // the contents against the side of the screen.
        if Geometry.nearlyEqual(Double(contentOffset.x), 0) {
            imageScrollView.contentOffset = CGPoint(x: -leftMargin, y: 0)
        } else {
            imageScrollView.contentOffset = contentOffset
        }
        hideCursorAndNormalizeAllMarks()
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        })
    }

    func undoablySetDiagramImageAndResetLadder(_ image: UIImage?,
                                               imageIsUpscaled: Bool,
                                               transform: CGAffineTransform,
                                               scale: CGFloat,
                                               contentOffset: CGPoint) {
        os_log("undoablySetDiagramImageAndResetLadder(_:)", log: .action, type: .info)
        currentDocument?.undoManager.beginUndoGrouping()
        undoablySetCalibration(Calibration())
        ladderView.deleteAllInLadder()
        undoablySetDiagramImage(image, imageIsUpscaled: imageIsUpscaled, transform: transform, scale: scale, contentOffset: contentOffset)
        currentDocument?.undoManager.endUndoGrouping()
        ladderView.viewMaxWidth = imageView.frame.width
        if !showingPDFToolbar {
            mode = .normal
        }
    }

    func scaleImageForImageView(_ image: UIImage?) -> UIImage? {
        os_log("scaleImageForImageView", log: .action, type: .info)
        guard let image = image else { return nil }
        // Downscale upscaled images
        if diagram.imageIsUpscaled {
            if let cgImage = image.cgImage {
                return UIImage(cgImage: cgImage, scale: pdfScaleFactor, orientation: .up)
            }
        }
        return image
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
        self.separatorView?.showIndicator = false
        self.separatorView?.setNeedsDisplay()
        navigationController?.setToolbarHidden(true, animated: true)
        // Always hide cursor when opening hamburger menu.
        hideCursorAndNormalizeAllMarks()
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
            self.separatorView?.showIndicator = true
            self.separatorView?.setNeedsDisplay()
            self.setViewsNeedDisplay()
        })
    }

    // MARK: - UIImagePickerController delegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let chosenImage = info[.editedImage] as? UIImage
        // Images from photos are never upscaled.
        undoablySetDiagramImageAndResetLadder(chosenImage, imageIsUpscaled: false, transform: CGAffineTransform.identity, scale: 1.0, contentOffset: .zero)
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

}

import PhotosUI

extension DiagramViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        if let itemProvider = results.first?.itemProvider {
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if let image = image as? UIImage {
                            // Only PDFs are upscaled
                            self.undoablySetDiagramImageAndResetLadder(image, imageIsUpscaled: false, transform: CGAffineTransform.identity, scale: 1.0, contentOffset: .zero)
                        } else {
                            os_log("Error displaying image", log: .errors, type: .error)
                            UserAlert.showMessage(viewController: self, title: L("Error Loading Image"), message: L("Selected image could not be loaded."))
                        }
                    }
                }
            } else {
                os_log("Can't load item provider", log: .errors, type: .error)
            }
        }
    }

    func presentPhotosForImages() {
        presentPhotosPicker(filter: .images)
    }

    func presentPhotosPicker(filter: PHPickerFilter) {
        var configuration = PHPickerConfiguration()
        configuration.filter = filter
        // .selectionLimit defaults to 1, single selection

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
}
