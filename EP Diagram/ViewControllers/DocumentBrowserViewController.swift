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

class DocumentBrowserViewController: UIDocumentBrowserViewController {

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
        closeDiagramController {
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

    private func openDocumentURL(_ url: URL) {
        os_log("openDocumentURL(_:) %s", url.path)
        let document = DiagramDocument(fileURL: url)
        document.open { openSuccess in
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
        self.present(controller, animated: true)
        self.diagramViewController = diagramViewController
    }

    func closeDiagramController(completion: (()->Void)? = nil) {
        let compositeClosure = {
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
        let action: ((UIAlertAction)->Void) = { _ in
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                if let plugin = appDelegate.appKitPlugin {
                    if let nsWindow = self.view.window?.nsWindow {
                        let completion: ((URL)->Void) = { url in
                            Sandbox.storeDirectoryBookmark(from: url)
                            print("directoryURL", url as Any)
                        }
                        plugin.getDirectory(nsWindow: nsWindow, startingURL: nil, completion: completion)
                    }
                }
            }
        }
        UserAlert.showWarning(viewController: self, title: L("Add Directory To Sandbox"), message: L("In order to save diagram files to this folder, it is necessary to add the folder to the app sandbox.  Use the open dialog that appears when you select OK to select the folder.  You should only need to do this once per folder.  If you want to abort opening the file, select Cancel.  Note: You can reset the app sandbox at any time using the Clear Sandbox menu item in the Files menu."), action: action)
    }

    @IBAction func clearSandbox(_ sender: Any) {
        if let diagramViewController = diagramViewController {
            diagramViewController.clearSandbox(sender)
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


