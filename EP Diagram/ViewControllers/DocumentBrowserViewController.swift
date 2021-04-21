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

    var externalURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        allowsDocumentCreation = true
        localizedCreateDocumentActionTitle = L("Create New Diagram")
        browserUserInterfaceStyle = .light
        delegate = browserDelegate
        view.tintColor = .systemBlue
        installDocumentBrowser()

        let info = self.restorationInfo
        // Fail gently if cached file no longer exists.
        if let lastDocumentURLPath = info?[DiagramViewController.restorationFileNameKey] as? String,
           !lastDocumentURLPath.isEmpty,
           info?[DiagramViewController.restorationDoRestorationKey] as? Bool ?? false {
            if let docURL = FileIO.getDocumentsURL() {
                let fileURL = docURL.appendingPathComponent(lastDocumentURLPath)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    openDocument(url: fileURL)
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        print("document browser did appear")
        super.viewDidAppear(animated)

        if let externalURL = externalURL {
            if FileManager.default.fileExists(atPath: externalURL.path) {
                openDocument(url: externalURL)
                return
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("document browser disappeared")
    }

    func installDocumentBrowser() {
        browserDelegate.presentationHandler = { [weak self] url, error in
            guard error == nil else {
                //present error to user e.g UIAlertController
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
}

protocol DiagramEditorDelegate: AnyObject {
    func diagramEditorDidFinishEditing(_ controller: DiagramViewController, diagram: Diagram)
    func diagramEditorDidUpdateContent(_ controller: DiagramViewController, diagram: Diagram)
}

extension DocumentBrowserViewController: DiagramEditorDelegate {
    func diagramEditorDidFinishEditing(_ controller: DiagramViewController, diagram: Diagram) {
        currentDocument?.diagram = diagram
        // see https://developer.apple.com/forums/thread/670247
        closeDiagramController(completion: {  UIApplication.shared.windows.first?.rootViewController = self })
    }

    func diagramEditorDidUpdateContent(_ controller: DiagramViewController, diagram: Diagram) {
        currentDocument?.diagram = diagram
    }

    func displayDiagramController() {
        os_log("displayDiagramController()", log: .default, type: .default)
        guard !editingDocument, let document = currentDocument else { return }
        editingDocument = true
        let controller = DiagramViewController.navigationControllerFactory()
        let diagramViewController = controller.viewControllers[0] as? DiagramViewController
        diagramViewController?.diagramEditorDelegate = self
        diagramViewController?.diagram = document.diagram

        diagramViewController?.restorationInfo = restorationInfo
        restorationInfo = nil // don't need it any more

        // This is not used, probably can delete.
        diagramViewController?.restorationIdentifier = restorationIdentifier
        diagramViewController?.currentDocument = document
        // FIXME: This avoids the modal problem, but how to close document??
//        controller.modalPresentationStyle = .fullScreen
//        self.present(controller, animated: true)
        UIApplication.shared.windows.first?.rootViewController = diagramViewController?.navigationController

//        view.window?.rootViewController = controller


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
        currentDocument?.close()
        currentDocument = nil
    }

    func openRemoteDocument(_ inboundURL: URL, importIfNeeded: Bool) {
        revealDocument(at: inboundURL, importIfNeeded: importIfNeeded) { (url, error) in
            if let error = error {
                let alert = UIAlertController(title: L("Could Not Open Document"), message: L("EP Diagram could not open this document due to error \(error.localizedDescription)"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default))
                self.present(alert, animated: true)
                os_log("import did fail - %s", log: .errors, type: .error, error.localizedDescription)
            } else if let url = url {
                self.openDocument(url: url)
            }
        }
    }
}

extension DocumentBrowserViewController {
    func openDocument(url: URL) {
        guard !isDocumentCurrentlyOpen(url: url) else { return }
        closeDiagramController {
            let document = DiagramDocument(fileURL: url)
            document.open { openSuccess in
                guard openSuccess else {
                    print ("could not open \(url)")
                    return
                }
                self.currentDocument = document
                self.displayDiagramController()
            }
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

    @IBAction func openImageFile(_ sender: Any) {
        let controller = DiagramViewController.navigationControllerFactory()
        let diagramViewController = controller.viewControllers[0] as? DiagramViewController
        diagramViewController?.becomeFirstResponder()
        diagramViewController?.openImageFile(sender)
    }

}
