//
//  DocumentBrowserViewController.swift
//  EP Diagram
//
//  Created by David Mann on 11/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

enum NavigationContext {
  case launched
  case browsing
  case editing
}

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentPickerDelegate {

    var presentationContest: NavigationContext = .launched
    var currentDocument: DiagramDocument?
    var editingDocument = false
    var browserDelegate = DocumentBrowserDelegate()
    var restorationInfo: [AnyHashable: Any]?

    weak var diagramViewController: DiagramViewController?

    override func viewDidLoad() {
        os_log("viewDidLoad() - DocumentBrowserViewController", log: .default, type: .default)

        super.viewDidLoad()
        allowsDocumentCreation = true
        allowsPickingMultipleItems = false
        localizedCreateDocumentActionTitle = L("Create New Diagram")
        browserUserInterfaceStyle = .light
        delegate = browserDelegate
        view.tintColor = .systemBlue
        installInportHandler()

        let info = self.restorationInfo
        if info?[DiagramViewController.restorationDoRestorationKey] as? Bool ?? false {
            if let documentURL = info?[DiagramViewController.restorationDocumentURLKey] as? URL {
                if let presentationHandler = browserDelegate.inportHandler {
                    presentationHandler(documentURL, nil)
                    openDocument(url: documentURL)
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        os_log("viewDidAppear(_:) - DocumentBrowserViewController", log: .default, type: .default)
        super.viewDidAppear(animated)

     }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        os_log("viewDidDisappear(_:) - DocumentBrowserViewController", log: .default, type: .default)
        super.viewDidDisappear(animated)
    }

    func installInportHandler() {
        browserDelegate.inportHandler = { [weak self] url, error in
            guard error == nil else {
                let alert = UIAlertController(title: L("Error Opening Diagram"), message: L("This diagram could not be opened."), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: L("OK"), style: .cancel, handler: { _ in }))
                self?.present(alert, animated: true)
                return
            }
            if let url = url, let self = self {
                self.openDocument(url: url)
            }
        }
    }

    func openDocument(url: URL) {
        os_log("openDocument(url:) %s", url.path)
        guard !isDocumentCurrentlyOpen(url: url) else {
            print("document is not currently open")
            return
        }
        closeDiagramController { [weak self] in
            guard let self = self else { return }
            if var persistentDirectoryURL = Sandbox.getPersistentDirectoryURL(forFileURL: url) {
                let didStartAccessing = persistentDirectoryURL.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        persistentDirectoryURL.stopAccessingSecurityScopedResource()
                    }
                }
                persistentDirectoryURL = persistentDirectoryURL.appendingPathComponent(url.lastPathComponent)
                let document = DiagramDocument(fileURL: persistentDirectoryURL)
                document.open { openSuccess in
                    guard openSuccess else {
                        print ("could not open \(url)")
                        self.getIOSBookmark(url: url)
                        return
                    }
                    self.currentDocument = document
                    self.displayDiagramController()
                }
            } else {
                print("could not get bookmark")
                self.openDocumentURL(url)
            }
        }
    }

    // See https://developer.apple.com/documentation/uikit/view_controllers/providing_access_to_directories
    func getIOSBookmark(url: URL) {
#if !targetEnvironment(macCatalyst)
        let documentPicker =
            UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.delegate = self

        // Set the initial directory.
        documentPicker.directoryURL = url

        // Present the document picker.
        present(documentPicker, animated: true, completion: nil)
#endif

    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        UserAlert.showMessage(viewController: self, title: "File can't be opened", message: "Cannot open file unless you agree to add this directory to the app sandbox.")
        print("Cannot open file since directory is not sandboxed.")
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        // Start accessing a security-scoped resource.
        guard url.startAccessingSecurityScopedResource() else {
            // Handle the failure here.
            return
        }

        // Make sure you release the security-scoped resource when you finish.
        defer { url.stopAccessingSecurityScopedResource() }

        // Use file coordination for reading and writing any of the URL’s content.
        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: url, error: &error) { (url) in

            let keys : [URLResourceKey] = [.nameKey, .isDirectoryKey]

            // Get an enumerator for the directory's content.
            guard let fileList =
                FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys) else {
                Swift.debugPrint("*** Unable to access the contents of \(url.path) ***\n")
                return
            }

            for case let file as URL in fileList {
                // Start accessing the content's security-scoped URL.
                guard url.startAccessingSecurityScopedResource() else {
                    UserAlert.showMessage(viewController: self, title: "Access Not Granted", message: "Cannot access diagram files in this directory.")
                    return
                }

                // Do something with the file here.
                Swift.debugPrint("chosen file: \(file.lastPathComponent)")
                Sandbox.storeDirectoryBookmark(from: url)
                UserAlert.showMessage(viewController: self, title: "Access Granted", message: "Access has been granted to \(file.deletingLastPathComponent().lastPathComponent).  Select again a diagram file in this directory or select Create New Diagram.")
                // Make sure you release the security-scoped resource when you finish.
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    private func openDocumentURL(_ url: URL) {
        os_log("openDocumentURL(_:) %s", url.path)
        let document = DiagramDocument(fileURL: url)
        document.open { [weak self] openSuccess in
            guard let self = self else { return }
            guard openSuccess else {
                print ("could not open \(url)")
                return
            }
            self.currentDocument = document
            self.displayDiagramController(requestSandboxExpansion: true)
        }
    }

    private func isDocumentCurrentlyOpen(url: URL) -> Bool {
        if let document = currentDocument {
            if document.fileURL == url && document.documentState != .closed {
                return true
            }
        }
        return false
    }

    @objc func displayDiagramController(requestSandboxExpansion: Bool = false) {
        os_log("displayDiagramController()", log: .default, type: .default)
        guard !editingDocument else { return }
        guard let document = currentDocument else { return }

        editingDocument = true

        let controller = DiagramViewController.navigationControllerFactory()

        let diagramViewController = controller.viewControllers[0] as? DiagramViewController
        diagramViewController?.currentDocument = document
        diagramViewController?.diagramEditorDelegate = self
        diagramViewController?.diagram = document.diagram
        diagramViewController?.requestSandboxExpansion = requestSandboxExpansion

        diagramViewController?.restorationInfo = restorationInfo
        restorationInfo = nil // don't need it any more

        controller.modalPresentationStyle = .fullScreen

        // From Stackoverflow https://stackoverflow.com/questions/67459304/how-to-avoid-strange-behavior-when-scene-based-document-mac-catalyst-app-reopens/67815273#67815273 but doesn't seem necessary
//        if(self.view.window != nil) {
//               //This document browser's view is in the view hierarchy, so present as usual
//               self.present(controller, animated: true)
//           }
//           else {
//               //This document browser's view is not in the view hierarchy, find the view that is
//               let topWindow = UIApplication.shared.connectedScenes.filter({$0.activationState == .foregroundActive})
//                   .map({$0 as? UIWindowScene})
//                   .compactMap({$0})
//                   .first?.windows
//                   .filter({$0.isKeyWindow}).first
//               let rootController = topWindow?.rootViewController
//               rootController?.present(controller, animated: true)
//           }


        self.present(controller, animated: true)
        self.diagramViewController = diagramViewController
    }

    func closeDiagramController(completion: (()->Void)? = nil) {
        let compositeClosure = { [weak self] in
            guard let self = self else { return }
            self.closeCurrentDocument()
            self.editingDocument = false
            completion?()
        }
        if editingDocument {
            self.dismiss(animated: true) {
                compositeClosure()
            }
        } else {
            compositeClosure()
        }
    }

    private func closeCurrentDocument() {
        guard currentDocument != nil else {
            print("current document is nil!"); return
        }
        currentDocument?.close() { success in
            guard success else {
                print("failed to close document")
                return
            }
        }
        currentDocument = nil
    }

}

protocol DiagramEditorDelegate: AnyObject {
    func diagramEditorDidFinishEditing(_ controller: DiagramViewController, diagram: Diagram)
    func diagramEditorDidUpdateContent(_ controller: DiagramViewController, diagram: Diagram)
}

extension DocumentBrowserViewController: DiagramEditorDelegate {
    func diagramEditorDidFinishEditing(_ controller: DiagramViewController, diagram: Diagram) {
        os_log("diagramEditorDidFinishEditing(_:diagram:) - DocumentBrowserViewController", log: .default, type: .default)
        currentDocument?.diagram = diagram
        closeDiagramController()
    }

    func diagramEditorDidUpdateContent(_ controller: DiagramViewController, diagram: Diagram) {
        os_log("diagramEditorDidUpdateContent(_:diagram:) - DocumentBrowserViewController", log: .default, type: .default)
        currentDocument?.diagram = diagram
    }
}

#if targetEnvironment(macCatalyst)
extension DocumentBrowserViewController {

    // Forward actions to the diagramViewController as needed

    // Edit menu

    @IBAction func undo(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.undo(sender)
        }
    }

    @IBAction func redo(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.redo(sender)
        }
    }

    // View menu

    @IBAction func doZoom(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.doZoom(sender)
        }
    }

    // Diagram menu

    @IBAction func getDiagramInfo(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.getDiagramInfo(sender)
        }
    }

    @IBAction func importPhoto(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.importPhoto(sender)
        }
    }

    @IBAction func importImageFile(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.importImageFile(sender)
        }
    }

    @IBAction func selectLadder(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.selectLadder(sender)
        }
    }

    @IBAction func editLadder(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.editLadder(sender)
        }
    }

    @IBAction func sampleDiagrams(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.sampleDiagrams(sender)
        }
    }

    @IBAction func macCloseDocument(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.macCloseDocument(sender)
        }
    }

    @IBAction func macShowCalibrateToolbar(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.macShowCalibrateToolbar(sender)
        }
    }

    @IBAction func macSnapshotDiagram(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.macSnapshotDiagram(sender)
        }
    }

    @IBAction func macSelectImage(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.macSelectImage(sender)
        }
    }

    @IBAction func addDirectoryToSandbox(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.addDirectoryToSandbox(sender)
        }
    }

    @IBAction func clearSandbox(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.clearSandbox(sender)
        }
    }

    @objc func renameDiagram() {
        if let diagramViewController = diagramViewController {
            diagramViewController.renameDiagram()
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
         if action == #selector(undo(_:)) {
            return diagramViewController?.imageScrollView.isActivated ?? false &&
                currentDocument?.undoManager?.canUndo ?? false
        } else if action == #selector(redo(_:)) {
            return diagramViewController?.imageScrollView.isActivated ?? false &&
                currentDocument?.undoManager?.canRedo ?? false
        } else {
            return super.canPerformAction(action, withSender: sender)
        }
    }
}
#endif


