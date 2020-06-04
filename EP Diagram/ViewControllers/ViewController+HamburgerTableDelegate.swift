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
    func takePhoto()
    func selectPhoto()
    func about()
    func openDiagram()
    func saveDiagram()
    func sampleDiagrams()
    func editTemplates()
    func help()
    func lockImage()
    func hideHamburgerMenu()
    func showHamburgerMenu()
}

extension ViewController: HamburgerTableDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    func lockImage() {
        _imageIsLocked = !_imageIsLocked
        // Turn off scrolling and zooming, but allow single taps to generate marks with cursors.
        imageScrollView.isScrollEnabled = !_imageIsLocked
        imageScrollView.pinchGestureRecognizer?.isEnabled = !_imageIsLocked
        cursorView.imageIsLocked = _imageIsLocked
        cursorView.setNeedsDisplay()
    }

    var imageIsLocked: Bool {
        get { return _imageIsLocked }
        set(newValue) { _imageIsLocked = newValue}
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
        os_log("About EP Diagram: version = %s build = %s", log: OSLog.debugging, type: .info, version, build)
        Common.showMessage(viewController: self, title: L("About EP Diagram"), message: "Copyright 2020 EP Studios, Inc.\nVersion " + version)
    }

    func openDiagram() {
        os_log("Open diagram", log: OSLog.action, type: .info)
        // Open list of saved diagrams
        do {
            guard let documentDirURL = FileIO.getURL(for: .documents) else {
                os_log("File error: user document directory not found!", log: .errors, type: .error)
                Common.showMessage(viewController: self, title: L("File Error"), message: "User document directory not found!")
                throw FileIO.FileIOError.documentDirectoryNotFound
            }
            let diagramDirURL = documentDirURL.appendingPathComponent(FileIO.epdiagramDir, isDirectory: true)
            if !FileManager.default.fileExists(atPath: diagramDirURL.path) {
                throw FileIO.FileIOError.diagramDirectoryNotFound
            }
            let fileURLs = try FileManager.default.contentsOfDirectory(at: diagramDirURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
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

    private func resetLadder() {
        ladderView.resetLadder()
        undoManager?.removeAllActions()
        updateUndoRedoButtons()
        setViewsNeedDisplay()
    }

    func saveDiagram() {
        os_log("saveDiagram()", log: OSLog.action, type: .info)
        showSaveDiagramAlert()
    }

    fileprivate func saveDiagramFiles(diagramDirURL: URL) {
        do {
            let imageData = self.imageView.image?.pngData()
            let imageURL = diagramDirURL.appendingPathComponent("image.png", isDirectory: false)
            try imageData?.write(to: imageURL)
            let encoder = JSONEncoder()
            let ladderData = try? encoder.encode(self.ladderView.ladder)
            let ladderURL = diagramDirURL.appendingPathComponent("ladder.json", isDirectory: false)
            FileManager.default.createFile(atPath: ladderURL.path, contents: ladderData, attributes: nil)
        } catch {
            os_log("Error: %s", log: .errors, type: .error, error.localizedDescription)
            Common.showMessage(viewController: self, title: L("File Error"), message: "Error: \(error.localizedDescription)")
        }
    }

    func getEPDiagramsDirURL() throws -> URL {
        guard let documentDirURL = FileIO.getURL(for: .documents) else {
            throw FileIO.FileIOError.documentDirectoryNotFound
        }
        let epDiagramsDirURL = documentDirURL.appendingPathComponent(FileIO.epdiagramDir, isDirectory: true)
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
    func getDiagramDirURLNonThrowing(for filename: String) -> URL? {
        return try? getDiagramDirURL(for: filename)
    }

    func diagramDirURLExists(for filename: String) throws -> Bool {
        let epDiagramsDirURL = try getEPDiagramsDirURL()
        let diagramDirURL = epDiagramsDirURL.appendingPathComponent(filename, isDirectory: true)
        return FileManager.default.fileExists(atPath: diagramDirURL.path)
    }

    func handleSaveDiagram(filename: String?) {
        os_log("handleSaveDiagram()", log: OSLog.action, type: .info)
        guard let filename = filename, !filename.isEmpty else {
            Common.showMessage(viewController: self, title: L("Name is Required"), message: L("You must enter a name for this diagram"))
            return }
        do {
            if try !diagramDirURLExists(for: filename) {
                let diagramDirURL = try getDiagramDirURL(for: filename)
                saveDiagramFiles(diagramDirURL: diagramDirURL)
            }
            else {
                os_log("diagram file already exists", log: OSLog.action, type: .info)
                Common.ShowWarning(viewController: self, title: "File Already Exists", message: "A diagram named \(filename) already exists.  Overwrite?") { _ in
                    let diagramDirURL = self.getDiagramDirURLNonThrowing(for: filename)
                    if let diagramDirURL = diagramDirURL {
                        self.saveDiagramFiles(diagramDirURL: diagramDirURL)
                    }
                }
            }
        } catch FileIO.FileIOError.documentDirectoryNotFound {
            os_log("FileIOError.documentDirectoryNotFound", log: OSLog.errors, type: .error)
        } catch FileIO.FileIOError.diagramDirectoryNotFound {
            os_log("FileIOError.diagramDirectoryNotFound", log: OSLog.errors, type: .error)
        } catch {
            os_log("File error: %s", log: OSLog.errors, type: .error, error.localizedDescription)
        }

    }

    func showSaveDiagramAlert() {
        Common.showTextAlert(viewController: self, title: L("Save Diagram"), message: L("Enter a unique name for this diagram"), preferredStyle: .alert, handler: { name in self.handleSaveDiagram(filename: name) })
    }

    func sampleDiagrams() {
        os_log("sampleDiagrams()", log: OSLog.action, type: .info)
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
        navigationController?.setToolbarHidden(true, animated: true)
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

