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
    func test()
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
            UserAlert.showMessage(viewController: viewController, title: title, message: message)
        }
    }
}

// MARK: -

extension DiagramViewController: HamburgerTableDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate, UIDocumentPickerDelegate {
    
    var imageIsLocked: Bool {
        get { _imageIsLocked }
        set(newValue) { _imageIsLocked = newValue}
    }

    var ladderIsLocked: Bool {
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
                    // FIXME: currentDocument.fileURL not changing to newURL.
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
        // TODO: If there are more fields, then include this and add SwiftUI view.
        // show dialog with diagram info here.
        // TODO: Option to edit diagram info?
        // also consider killing this.  File app gives file info.
        print("Name = \(diagram.name ?? "unnamed")")
        print("Description = \(diagram.longDescription)")
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
        let versionBuild = Version.appVersion()
        let version = versionBuild.version ?? L("unknown")
        let build = versionBuild.build ?? L("unknown")
        os_log("EP Diagram: version = %s build = %s", log: OSLog.debugging, type: .info, version, build)
        UserAlert.showMessage(
            viewController: self,
            title: L("EP Diagram"),
            message: L("Copyright 2020 EP Studios, Inc.\nVersion \(version)"))
    }

    // Use to test features during development
    #if DEBUG
    func test() {
        os_log("test()", log: .debugging, type: .debug)
        showSlantMenu()
//        ladderView.ladder.reregisterAllMarks()
//        print(ladderView.ladder.registry)
//        let ladder = ladderView.ladder
//        for region in ladder.regions {
//            for mark in region.marks {
//                os_log("%s", log: .test, type: .debug, mark.debugDescription)
////                print("test \(mark.groupedMarkIds)")
//            }
//        }


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
        print("urls = \(urls)")
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

//    private func resetLadder() {
//        // FIXME: this makes ladder default ladder and it shouldn't.
//        ladderView.resetLadder()
//        // FIXME: decide whether to reset undo here
////        undoManager?.removeAllActions()
//        updateUndoRedoButtons()
//        setViewsNeedDisplay()
//    }

    @objc func setDiagramImage(_ image: UIImage?) {
        os_log("setDiagramImage(_:)", log: .action, type: .info)
        currentDocument?.undoManager.registerUndo(withTarget: self, selector: #selector(setDiagramImage), object: imageView.image)
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        diagram.ladder.clear()
        let scaledImage = scaleImageForImageView(image)
        diagram.image = scaledImage
        imageView.image = scaledImage
//        imageView.transform = diagram.transform
        imageScrollView.zoomScale = 1.0
        imageScrollView.contentOffset = CGPoint.zero
        hideCursorAndNormalizeAllMarks()
//        diagram.calibration.reset()
        setViewsNeedDisplay()
    }

    func scaleImageForImageView(_ image: UIImage?) -> UIImage? {
        os_log("scaleImageForImageView", log: .action, type: .info)
        guard let image = image else { return nil }
        // Downscale upscaled images
        if diagram.imageIsUpscaled {
            print(">>>> downscaling image")
            if let cgImage = image.cgImage {
                return UIImage(cgImage: cgImage, scale: pdfScaleFactor, orientation: .up)
            }
        }
        return image
    }

    //    - (UIImage *)scaleImageForImageView:(UIImage *)image {
    //        EPSLog(@"scaleImageForImageView");
    //        // Downscale upscaled images.
    //        if (self.imageIsUpscaled) {
    //            EPSLog(@">>>>>>Downscaling image");
    //            CGImageRef imageRef = image.CGImage;
    //            return [UIImage imageWithCGImage:(CGImageRef)imageRef scale:PDF_UPSCALE_FACTOR orientation:UIImageOrientationUp];
    //        }
    //        return image;
    //    }


 
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
            self.separatorView = HorizontalSeparatorView.addSeparatorBetweenViews(separatorType: .horizontal, primaryView: self.imageScrollView, secondaryView: self.ladderView, parentView: self.view)
        })
    }

    // MARK: - UIImagePickerController delegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let chosenImage = info[.editedImage] as? UIImage
        // Images from photos are never upscaled.
        diagram.imageIsUpscaled = false
        setDiagramImage(chosenImage)
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
                            self.diagram.imageIsUpscaled = false
                            self.setDiagramImage(image)
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
