//
//  ViewController+HamburgerTableDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 4/17/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import AudioToolbox
import os.log

protocol HamburgerTableDelegate: class {
    var hamburgerMenuIsOpen: Bool { get set }
    var constraintHamburgerLeft: NSLayoutConstraint { get set }
    var constraintHamburgerWidth: NSLayoutConstraint { get set }
    var maxBlackAlpha: CGFloat { get }
    var imageIsLocked: Bool { get set }
    var diagramIsLocked: Bool { get set }
    func takePhoto()
    func selectPhoto()
    func about()
    func test()
    func openDiagram()
    func saveDiagram()
    func snapshotDiagram()
    func renameDiagram()
    func duplicateDiagram()
    func lockLadder()
    func sampleDiagrams()
    func showPreferences()
    func editTemplates()
    func help()
    func lockImage()
    func hideHamburgerMenu()
    func showHamburgerMenu()
}

class ImageSaver: NSObject {
    var viewController: UIViewController?

    func writeToPhotoAlbum(image: UIImage, viewController: UIViewController) {
        self.viewController = viewController
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveImageError), nil)
    }

    @objc func saveImageError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        var title: String = ""
        var message: String = ""
        if let error = error {
            os_log("Error saving snapshot:  %s", log: .errors, type: .error,   error.localizedDescription)
            title = L("Error Saving Snapshot")
            message = L("Make sure you have allowed EP Diagram to save to the Photos Library in the Settings app.  Error message: \(error.localizedDescription)")
        }
        else {
            // Magic code to play system shutter sound.  We link AudioToolbox framework to make this work.  See http://iphonedevwiki.net/index.php/AudioServices for complete list os system sounds.  Note unlock sound (1101) doesn't seem to work.
            AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1108), nil)
            // See https://www.hackingwithswift.com/books/ios-swiftui/how-to-save-images-to-the-users-photo-library
            os_log("Snapshot successfully saved.", log: .action, type: .info)
            title = L("Success!")
            message = L("Diagram snapshot saved to Photo Library.")
        }
        if let viewController = viewController {
            Common.showMessage(viewController: viewController, title: title, message: message)
        }
    }
}

extension ViewController: HamburgerTableDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    func lockImage() {
        _imageIsLocked.toggle()
        // Turn off scrolling and zooming, but allow single taps to generate marks with cursors.
        imageScrollView.isScrollEnabled = !_imageIsLocked
        imageScrollView.pinchGestureRecognizer?.isEnabled = !_imageIsLocked
        cursorView.imageIsLocked = _imageIsLocked
        cursorView.setNeedsDisplay()
        AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1100), nil)
    }

    var imageIsLocked: Bool {
        get { return _imageIsLocked }
        set(newValue) { _imageIsLocked = newValue}
    }

    var diagramIsLocked: Bool {
        get { return _ladderIsLocked }
        set(newValue) { _ladderIsLocked = newValue }
    }

    var constraintHamburgerLeft: NSLayoutConstraint {
        get {
            return _constraintHamburgerLeft
        }
        set(newValue){
            _constraintHamburgerLeft = newValue
        }
    }
    var constraintHamburgerWidth: NSLayoutConstraint {
        get {
            return _constraintHamburgerWidth
        }
        set(newValue) {
            _constraintHamburgerWidth = newValue
        }
    }
    var maxBlackAlpha: CGFloat {
        get {
            return _maxBlackAlpha
        }
    }

    private static var subsystem = Bundle.main.bundleIdentifier!
    static let hamburgerCycle = OSLog(subsystem: subsystem, category: "hamburger")

    func takePhoto() {
        os_log("takePhoto()", log: OSLog.action, type: .info)
        let picker: UIImagePickerController = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            Common.showMessage(viewController: self, title: L("Camera error"), message: "Camera not available")
            return
        }
        picker.sourceType = .camera
        present(picker, animated: true, completion: nil)
        resetLadder()
    }

    func selectPhoto() {
        os_log("selectPhoto()", log: OSLog.action, type: .info)
        let picker: UIImagePickerController = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
        resetLadder()
    }

    func about() {
        let versionBuild = Version.getAppVersion()
        let version = versionBuild.version ?? L("unknown")
        let build = versionBuild.build ?? L("unknown")
        os_log("EP Diagram: version = %s build = %s", log: OSLog.debugging, type: .info, version, build)
        Common.showMessage(viewController: self, title: L("EP Diagram"), message: L("Copyright 2020 EP Studios, Inc.\nVersion \(version)"))
    }

    // FIXME: remove before release!!!!!
    // Use to test features during development
    func test() {
        os_log("test()", log: .debugging, type: .debug)
    }

    func openDiagram() {
        os_log("Open diagram", log: OSLog.action, type: .info)
        // Open list of saved diagrams
        do {
            let epDiagramsDirURL = try getEPDiagramsDirURL()
            let fileURLs = try FileManager.default.contentsOfDirectory(at: epDiagramsDirURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            if fileURLs.count < 1 {
                Common.showMessage(viewController: self, title: "No Saved Diagrams", message: "No previously saved diagrams found.")
                return
            }
            let filenames = fileURLs.map { $0.lastPathComponent }.sorted()
            diagramFilenames = filenames
            performSegue(withIdentifier: "showDiagramSelectorSegue", sender: self)
        } catch {
            os_log("Error: %s", error.localizedDescription)
        }
    }

    func saveDiagram() {
        os_log("saveDiagram()", log: OSLog.action, type: .info)
        if let name = diagram?.name {
            handleSaveDiagram(filename: name, overwrite: true)
        }
        else {
            showNameDiagramAlert()
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

    func renameDiagram() {
        os_log("renameDiagram()", log: .action, type: .info)
        if let name = diagram?.name {
            handleRenameDiagram(filename: name)
            if fileOpSuccessfullFlag {
                deleteDiagram(diagramName: name)
                fileOpSuccessfullFlag = false
            }
        }
        // if there is no name, handle as just save diagram
        else {
            // Modify this to note that this diagram has not been saved at all yet.
            showNameDiagramAlert()
        }
    }

    func duplicateDiagram() {
        os_log("duplicateDiagram()", log: .action, type: .info)
        if let name = diagram?.name {
            handleRenameDiagram(filename: name)
        }
        else {
            // Modify this to note that this diagram has not been saved at all yet.
            showNameDiagramAlert()
        }
    }

    func lockLadder() {
        os_log("lockDiagram()", log: .action, type: .info)
        _ladderIsLocked.toggle()
        // Turn off scrolling and zooming, but allow single taps to generate marks with cursors.
        ladderView.ladderIsLocked = _ladderIsLocked
        cursorView.allowTaps = !_ladderIsLocked
        ladderView.isUserInteractionEnabled = !_ladderIsLocked
        setViewsNeedDisplay()
        AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1100), nil)
    }

    func showNameDiagramAlert() {
        Common.showTextAlert(viewController: self, title: L("Save Diagram"), message: L("Enter a unique name for this diagram"), preferredStyle: .alert, handler: { name in self.handleSaveDiagram(filename: name) })
    }

    fileprivate func saveDiagramFiles(diagramDirURL: URL) {
        os_log("saveDiagramFiles()", log: .action, type: .info)
        do {
            let imageData = self.imageView.image?.pngData()
            let imageURL = diagramDirURL.appendingPathComponent(FileIO.imageFilename, isDirectory: false)
            try imageData?.write(to: imageURL)
            let encoder = JSONEncoder()
            let ladderData = try? encoder.encode(self.ladderView.ladder)
            let ladderURL = diagramDirURL.appendingPathComponent(FileIO.ladderFilename, isDirectory: false)
            FileManager.default.createFile(atPath: ladderURL.path, contents: ladderData, attributes: nil)
            fileOpSuccessfullFlag = true
        } catch {
            os_log("Error: %s", log: .errors, type: .error, error.localizedDescription)
            Common.ShowFileError(viewController: self, error: error)
        }
    }

    private func getEPDiagramsDirURL() throws -> URL {
        guard let documentDirURL = FileIO.getURL(for: .documents) else {
            throw FileIOError.documentDirectoryNotFound
        }
        P("documentDirURL = \(documentDirURL)")
        let epDiagramsDirURL = documentDirURL.appendingPathComponent(FileIO.epDiagramDir, isDirectory: true)
        if !FileManager.default.fileExists(atPath: epDiagramsDirURL.path) {
            try FileManager.default.createDirectory(atPath: epDiagramsDirURL.path, withIntermediateDirectories: true, attributes: nil)
        }
        return epDiagramsDirURL
    }

    func getDiagramDirURL(for filename: String) throws -> URL {
        let epDiagramsDirURL = try getEPDiagramsDirURL()
        let diagramDirURL = epDiagramsDirURL.appendingPathComponent(filename, isDirectory: true)
        if !FileManager.default.fileExists(atPath: diagramDirURL.path) {
            try FileManager.default.createDirectory(atPath: diagramDirURL.path, withIntermediateDirectories: true, attributes: nil)
        }
        return diagramDirURL
    }

    // non-throwing version of above
    private func getDiagramDirURLNonThrowing(for filename: String) -> URL? {
        return try? getDiagramDirURL(for: filename)
    }

    private func diagramDirURLExists(for filename: String) throws -> Bool {
        let epDiagramsDirURL = try getEPDiagramsDirURL()
        let diagramDirURL = epDiagramsDirURL.appendingPathComponent(filename, isDirectory: true)
        return FileManager.default.fileExists(atPath: diagramDirURL.path)
    }

    private func handleRenameDiagram(filename: String) {
        Common.showTextAlert(viewController: self, title: L("Rename Diagram"), message: L("Enter a new name for diagram \(filename)"), preferredStyle: .alert, handler: { name in self.handleSaveDiagram(filename: name, overwrite: false) })
    }

    private func handleSaveDiagram(filename: String?, overwrite: Bool = false) {
        os_log("handleSaveDiagram()", log: OSLog.action, type: .info)
        guard var filename = filename, !filename.isEmpty else {
            Common.showMessage(viewController: self, title: L("Name is Required"), message: L("You must enter a name for this diagram."))
            return }
        filename = cleanupFilename(filename)
        diagram?.name = filename
        do {
            if try !diagramDirURLExists(for: filename) || overwrite {
                let diagramDirURL = try getDiagramDirURL(for: filename)
                saveDiagramFiles(diagramDirURL: diagramDirURL)
            }
            else {
                os_log("diagram file already exists", log: OSLog.action, type: .info)
                Common.ShowWarning(viewController: self, title: "File Already Exists", message: "A diagram named \(filename) already exists.  Overwrite?", okActionButtonTitle: L("Overwrite")) { _ in
                    if let diagramDirURL = self.getDiagramDirURLNonThrowing(for: filename) {
                        self.saveDiagramFiles(diagramDirURL: diagramDirURL)
                    }
                }
            }
        } catch {
            os_log("File error: %s", log: OSLog.errors, type: .error, error.localizedDescription)
            Common.ShowFileError(viewController: self, error: error)
        }
    }

    func cleanupFilename(_ filename: String) -> String {
        var invalidCharacters = CharacterSet(charactersIn: ":/")
        invalidCharacters.formUnion(.newlines)
        invalidCharacters.formUnion(.illegalCharacters)
        invalidCharacters.formUnion(.controlCharacters)

        let newFilename = filename
            .components(separatedBy: invalidCharacters)
            .joined(separator: "_")
        return newFilename
    }

    func sampleDiagrams() {
        os_log("sampleDiagrams()", log: OSLog.action, type: .info)
    }

    func showPreferences() {
        os_log("showPreferences()", log: OSLog.action, type: .info)
        performSegue(withIdentifier: "showPreferencesSegue", sender: self)
    }

    private func resetLadder() {
        ladderView.resetLadder()
        undoManager?.removeAllActions()
        updateUndoRedoButtons()
        setViewsNeedDisplay()
    }

    func editTemplates() {
        os_log("editTemplates()", log: OSLog.action, type: .info)
        performSegue(withIdentifier: "showTemplateEditorSegue", sender: self)
    }

    func help() {
        os_log("help()", log: OSLog.action, type: .info)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let chosenImage = info[.editedImage] as? UIImage
        imageView.image = chosenImage
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    
    @objc func toggleHamburgerMenu() {
        if hamburgerMenuIsOpen {
            hideHamburgerMenu()
        }
        else {
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
    
}

